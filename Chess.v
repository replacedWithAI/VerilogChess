module displayRowAndColumn( // might delete this later when the VGA works
	input [2:0] value,
	input isRow,
	output reg [6:0] display
);
	always @(*) begin
		case(value)
			case (value)
			3'd0: display = isRow ? 7'b0001000 : 7'b1111001;
			3'd1: display = isRow ? 7'b0000000 : 7'b0100100;
			3'd2: display = isRow ?	7'b1000110 : 7'b0110000;
			3'd3: display = isRow ? 7'b0100001 : 7'b0011001;
			3'd4: display = isRow ? 7'b0000110 : 7'b0010010;
			3'd5: display = isRow ? 7'b0001110 : 7'b0000010;
			3'd6: display = isRow ? 7'b0010000 : 7'b1111000;
			3'd7: display = isRow ? 7'b0001101 : 7'b0000000;
			default: ;
		endcase
	end
endmodule

module displayPiece(
	input [3:0] value;
	output reg [6:0] display;
);
	always @(*) begin
		case(value)
			5'd1, 5'd7: display = 7'b0001100;
			5'd2, 5'd8: display = 7'b0101111;
			5'd3, 5'd9: display = 7'b0101011;
			5'd4, 5'd10: display = 7'b0000011;
			5'd5, 5'd11: display = 7'b0011000;
			5'd6, 5'd12: display = 7'b0001000;
			default: display = 7'b1111111;
		endcase
	end
endmodule

module displayTurn(
	input value,
	output reg[6:0] display
);
	always @(*) begin
		1'b0: display = 7'b1111001;
		1'b1: display = 7'b0100100;
	end
endmodule

module Chess(
	input [6:0] SW,
	input clock,
	input reset,
	input select
	output wire [6:0] hex0Display,
	output wire [6:0] hex1Display,
	output wire [6:0] hex2Display,
	output wire [6:0] hex3Display,
	output wire [6:0] hex4Display,
	output wire [6:0] hex5Display,
);
	reg [4:0] board[63:0];

	function isInsideBoard; // might be redundant. Any number bigger than 7 is truncated
		input reg signed [5:0] boardDimension;
		beginwire [6:0] currSquare = ;
			 isInsideBoard = (boardDimension >= 0 && boardDimension < 8);
		end
	endfunction


	function isWhitePiece;
		input reg [6:0] currSquare;
		begin
			isWhitePiece = (board[currSquare] >= 5'b1 && board[currSquare] <= 5'd6);
		end
	endfunction

	/*
		for each square in the 64 area board, the values for each square mean:
			0: empty
			1: white pawn
			2: white rook
			3: white knight
			4: white bishop:
			5: white queen
			6: white king:
			7-12: black pawn to black queen
			
		also, a1 = 0, b1 = 1, and so on so forth across the row, then
		a2 = 8, b2 = 9. Right and up until h8 = 63
	*/
	task initialiseBoard;

		reg [3:0] i;
		reg [3:0] j;

		begin
			board[0] = 5'd2;
			board[1] = 5'd3;
			board[2] = 5'd4;
			board[3] = 5'd5;
			board[4] = 5'd6;
			board[5] = 5'd4;
			board[6] = 5'd3;
			board[7] = 5'd2;
			
			for (i = 0; i < 8; i = i + 1) begin
				board[i + 8] = 5'd1;
			end
			
			for (i = 0; i < 8; i = i + 1) begin
				board[i + 48] = 5'd7;
			end
			
			board[56] = 5'd8;
			board[57] = 5'd9;
			board[58] = 5'd10;
			board[59] = 5'd11;
			board[60] = 5'd12;
			board[61] = 5'd10;
			board[62] = 5'd9;
			board[63] = 5'd8;
					
			for (i = 2; i < 6; i = i + 1) begin
				for (j = 0; j < 8; j = j + 1) begin
					board[i * 8 + j] = 5'd0;
				end
			end
		end
	endtask
	
	// -----------------------------------------------------------------------------------------------------------------
	// compute squares that pieces can reach. Does not mean the move is "legal" though

	task clearReachableSquares;
		output reg [63:0] reachable;
		
		reg[7:0] i;

		begin
			for (i = 0; i < 64; i = i+1)
				reachable[i] = 1'b0;
		end
	endtask


	task canLandOnSquare;
		input reg [5:0] currSquare;
		input reg signed [4:0] relativeNextRow;
		input reg signed [4:0] relativeNextColumn;
		inout reg [63:0] reachable;
		output reg blocked;

		reg signed [5:0] currSquareRow; // board dimensions are always positive, but the code might enter negatives
		reg signed [5:0] currSquareColumn;
		reg isWhite;
		reg signed[4:0] nextRow;
		reg signed[4:0] nextColumn;
		reg signed[7:0] nextSquare;

		begin
			blocked = 1'b0;
			currSquareColumn = currSquare / 8;
			currSquareRow = currSquare % 8;
			isWhite = (board[currSquare] <= 5'd6);

			nextColumn = currSquareColumn + relativeNextColumn;
			nextRow = currSquareRow + relativeNextRow;

			if (isInsideBoard(nextRow) && isInsideBoard(nextColumn)) begin
				nextSquare = nextColumn * 8 + nextRow;

				if (board[nextSquare] == 5'd0) reachable[nextSquare] = 1'b1;
				else begin
					if ((board[nextSquare] <= 5'd6) != isWhite)
						reachable[nextSquare] = 1'b1;
					blocked = 1'b1;
				end
			end
		end
	endtask


	task computeSlidingReachableSquares;
		input reg [6:0] currSquare;
		input reg signed [5:0] rowDirection;
		input reg signed [5:0] columnDirection;
		inout reg [63:0] reachable;

		reg blocked; // 1 if true, 0 if false
		reg signed[4:0] i;

		begin
			blocked = 1'b0;

			for (i = 1; i < 8; i = i + 1) begin
				if (!blocked)
					canLandOnSquare(currSquare, i * rowDirection, i * columnDirection, reachable, blocked);
			end
		end
	endtask


	task canReachVerticallyHorizontally;
		input reg [6:0] currSquare;
		inout reg [63:0] reachable;
		
		begin
			computeSlidingReachableSquares(currSquare, 1, 0, reachable);
			computeSlidingReachableSquares(currSquare, 0, 1, reachable);
			computeSlidingReachableSquares(currSquare, -1, 0, reachable);
			computeSlidingReachableSquares(currSquare, 0, -1, reachable);
		end
	endtask


	task canReachDiagonally;
		input reg [6:0] currSquare;
		inout reg [63:0] reachable;
		
		begin
			computeSlidingReachableSquares(currSquare, 1, 1, reachable);
			computeSlidingReachableSquares(currSquare, 1, -1, reachable);
			computeSlidingReachableSquares(currSquare, -1, 1, reachable);
			computeSlidingReachableSquares(currSquare, -1, -1, reachable);
		end
	endtask


	task knightCanReach;
		input reg [6:0] currSquare;
		inout reg [63:0] reachable;
		
		reg dummyReg;
		begin
			canLandOnSquare(currSquare,  2,  1, reachable, dummyReg);
			canLandOnSquare(currSquare,  2, -1, reachable, dummyReg);
			canLandOnSquare(currSquare, -2,  1, reachable, dummyReg);
			canLandOnSquare(currSquare, -2, -1, reachable, dummyReg);
			canLandOnSquare(currSquare,  1,  2, reachable, dummyReg);
			canLandOnSquare(currSquare,  1, -2, reachable, dummyReg);
			canLandOnSquare(currSquare, -1,  2, reachable, dummyReg);
			canLandOnSquare(currSquare, -1, -2, reachable, dummyReg);	
		end
	endtask


	task pawnCanReach; // no enpassant and promotion yet
		input reg [5:0] currSquare;
		inout reg [63:0] reachable;
		
		reg signed [4:0] currRow;
		reg signed [4:0] currColumn;
		reg isWhite;
		reg signed [1:0] forwardDirection;
		reg [3:0] startingColumn;
		reg signed [4:0] nextRow;
		reg signed [4:0] nextColumn;
		reg signed [2:0] diagonalSquareRow; 
		reg signed [6:0] nextSquare;

		begin
			currColumn = currSquare / 8;
			currRow = currSquare % 8;
			isWhite = (board[currSquare] <= 4'd6);
			forwardDirection = isWhite ? 1 : -1;
			startingColumn = isWhite ? 1 : 6;
			nextColumn = currColumn + forwardDirection;

			if (isInsideBoard(nextColumn)) begin
				nextSquare = currRow + nextColumn * 8;

				if (board[nextSquare] == 5'd0) begin
					reachable[nextSquare] = 1'b1;

					if (currColumn == startingColumn) begin
						nextSquare = nextSquare + forwardDirection * 8;
						reachable[nextSquare] = board[nextSquare] == 5'd0 ? 1'd1 : 1'd0;
					end
				end

				for (diagonalSquareRow = -1; diagonalSquareRow <= 1; diagonalSquareRow = diagonalSquareRow + 2) begin
					nextRow = currRow + diagonalSquareRow;
					if (isInsideBoard(nextRow) && (board[nextColumn * 8 + nextRow] <= 5'd6) != isWhite
						&& board[nextColumn * 8 + nextRow] != 5'd0)
						reachable[nextColumn * 8 + nextRow] = 1'b1;
				end
			end
		end
	endtask


	// knight, pawn, and king are the only pieces that have unique logic. Need manual implementations
	// Castling not implemented yet
	task kingCanReach;
		input reg[5:0] currSquare;
		inout reg [63:0] reachable;
		
		reg dummyReg;
		reg signed [2:0] i;
		reg signed [2:0] j;

		begin
			for (i = -1; i <= 1; i = i + 1) begin
				for (j = -1; j <= 1; j = j + 1) begin

				if (i != 0 || j != 0)
					canLandOnSquare(currSquare, i, j, reachable, dummyReg);

				end
			end
		end
	endtask


	task computeReachableSquares;
		input reg [5:0] currSquare;
		output reg [63:0] reachable;

		reg [4:0] pieceType;

		begin
			reachable = 64'd0;
			pieceType = board[currSquare] > 5'd6 ? board[currSquare] - 5'd6 : board[currSquare];

			case(pieceType)
				5'd1: pawnCanReach(currSquare, reachable);
				5'd2: canReachVerticallyHorizontally(currSquare, reachable);
				5'd3: knightCanReach(currSquare, reachable);
				5'd4: canReachDiagonally(currSquare, reachable);
				5'd5: begin	
					canReachVerticallyHorizontally(currSquare, reachable);
					canReachDiagonally(currSquare, reachable);
				end
				5'd6: kingCanReach(currSquare, reachable);
				default: ;
			endcase
		end
	endtask

	// -----------------------------------------------------------------------------------------------------------------
	// isCheck logic
	
	task getFirstPieceInDirection;
		input reg [5:0] currSquare;
		input reg signed [5:0] rowDirection;
		input reg signed [5:0] columnDirection;
		input reg whiteIsAttacking;
		inout reg isAttacked;

		reg signed [4:0] i;
		reg signed [4:0] currRow;
		reg signed [4:0] currColumn;
		reg signed [4:0] nextRow;
		reg signed [4:0] nextColumn;
		reg [4:0] piece;
		reg [4:0] pieceType;
		reg isDiagonal;

		begin
			currRow = currSquare % 8;
			currColumn = currSquare / 8;
			piece = 5'd0;

			for (i = 1; i < 8; i = i + 1) begin
				nextRow = currRow + i * rowDirection;
				nextColumn = currColumn + i * columnDirection;

				if (piece == 5'd0 && isInsideBoard(nextRow) && isInsideBoard(nextColumn) && board[nextColumn * 8 + nextRow] != 5'd0)
					piece = board[nextColumn * 8 + nextRow];
			end

			if (piece != 5'd0 && (piece >= 5'd1 && piece <= 5'd6) == whiteIsAttacking) begin
				pieceType = whiteIsAttacking ? piece : piece - 5'd6;
				isDiagonal = (rowDirection != 0 && columnDirection != 0);
				if (pieceType == 5'd5 || (isDiagonal ? pieceType == 5'd4 : pieceType == 5'd2)) 
					isAttacked = 1'b1;
			end
		end
	endtask


	task getPieceByFixedOffset;
		input reg [5:0] currSquare;
		input reg signed [5:0] rowDirection;
		input reg signed [5:0] columnDirection;
		input reg [4:0] attackingPieceType;
		inout reg isAttacked;

		reg signed [4:0] nextRow;
		reg signed [4:0] nextColumn;
		
		begin
			nextRow = currSquare % 8 + rowDirection;
			nextColumn = currSquare / 8 + columnDirection;

			if (isInsideBoard(nextRow) && isInsideBoard(nextColumn) && board[nextColumn * 8 + nextRow] == attackingPieceType)
				isAttacked = 1'b1;
		end
	endtask


	task findKing;
		input reg isBlackTurn;
		output reg[5:0] kingSquare;
		output reg kingFound;

		reg [6:0] i;
		reg [4:0] kingPiece;

		begin
			kingFound = 1'b0;
			kingPiece = isBlackTurn ? 5'd12 : 5'd6;
			for (i = 0; i < 64; i = i + 1) begin
				if (board[i] == kingPiece) begin
					kingSquare = i;
					kingFound = 1'b1;
				end
			end
		end
	endtask

	// brute force check all squares that attackers can reach the king square
	task isChecked;
		input reg isBlackTurn;
		output reg checked;
		
		reg [5:0] kingSquare;
		reg [4:0] attackingPieceType;
		reg found;
		reg signed [2:0] i;
		reg signed [2:0] j;
		reg signed [1:0] pawnDirection;

		begin : check
			checked = 1'b0;
			
			findKing(isBlackTurn, kingSquare, found);
			if (!found) disable check;

			for (i = -1; i <= 1; i = i + 1) begin // queen, bishop, rook attack
				for (j = -1; j <= 1; j = j + 1) begin

				if (i != 0 || j != 0)
					getFirstPieceInDirection(kingSquare, i, j, isBlackTurn, checked);

				end
			end

			i = 3'b0;
			j = -3'd1;
			attackingPieceType = isBlackTurn ? 5'd3 : 5'd9;

			getPieceByFixedOffset(kingSquare, 1, 2, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, 1, -2, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, 2, 1, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, 2, -1, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, -1, 2, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, -1, -2, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, -2, 1, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, -2, -1, attackingPieceType, checked);

			i = 3'b0;
			j = 3'd0;
			attackingPieceType = isBlackTurn ? 5'd6 : 5'd12;

			// pretty unintuitive because this checks if a king is adjacent to an enemy king, obviously illegal
			// but this task checks if the king's square is safe, ignoring how it got there. So this is necessary
			for (i = -1; i <= 1; i = i + 1) begin 
				for (j = -1; j <= 1; j = j + 1) begin

				if (i != 0 || j != 0)
					getPieceByFixedOffset(kingSquare, i, j, attackingPieceType, checked);

				end
			end

			pawnDirection = isBlackTurn ? -1 : 1; // the opposite direction enemy pawns can move
			attackingPieceType = isBlackTurn ? 5'd1 : 5'd7;
			getPieceByFixedOffset(kingSquare, 1, pawnDirection, attackingPieceType, checked);
			getPieceByFixedOffset(kingSquare, -1, pawnDirection, attackingPieceType, checked);
		end
	endtask

	// -----------------------------------------------------------------------------------------------------------------
	// legal moves logic
	
	// checks if a move, if allowed, exposes or doesn't defend a checked king
	task doesKingStaySafe;
		input reg [5:0] currSquare;
		input reg [5:0] targetSquare;
		output reg isSafeMove;

		reg [4:0] movedPiece;
		reg [4:0] capturedPiece;
		reg isWhite;
		reg checked;

		begin
			movedPiece = board[currSquare];
			capturedPiece = board[targetSquare];
			isWhite = (movedPiece >= 5'd1 && movedPiece <= 5'd6);

			board[targetSquare] = board[currSquare];
			board[currSquare] = 5'd0;
			isChecked(!isWhite, checked);
			isSafeMove = !checked;

			board[currSquare] = movedPiece;
			board[targetSquare] = capturedPiece;
		end
	endtask


	task computeLegalMoves;
		input reg [5:0] currSquare;
		output reg [63:0] legalMoves;

		reg [63:0] reachable;
		reg [6:0] i;
		reg isSafeMove;

		begin
			computeReachableSquares(currSquare, reachable);
			legalMoves = 64'b0;

			for (i = 0; i < 64; i = i + 1) begin
				
				if(reachable[i]) begin
					doesKingStaySafe(currSquare, i, isSafeMove);
					legalMoves[i] = isSafeMove;
				end
			
			end
		end
	endtask

	// -----------------------------------------------------------------------------------------------------------------
	// checkmate and stalemate logic

	task hasLegalMoves;
		input reg isBlackMove;
		output reg hasAnyLegal;

		reg [6:0] i;
		reg [63:0] legalMoves;

		begin : checkForMoves
			hasAnyLegal = 1'b0;

			for (i = 0; i < 64; i = i + 1) begin

				if (board[i] != 5'd0 && (board[i] >= 5'd7 && board[i] <= 5'd12) == isBlackMove) begin
					computeLegalMoves(i, legalMoves);

					if (legalMoves != 64'b0) begin
						hasAnyLegal = 1'b1;
						disable checkForMoves;
					end
					
				end

			end
		end
	endtask

	task isCheckmate;
		input reg isBlackMove;
		output reg checkmate;

		reg inCheck;
		reg hasAnyLegal;

		begin
			checkmate = 1'b0;

			isChecked(!isBlackMove, inCheck);
			if (inCheck) begin
				hasLegalMoves(!isBlackMove, hasAnyLegal);
				checkmate = !hasAnyLegal;
			end
		
		end
	endtask

	task isStalemate;
		input reg isBlackMove;
		output reg stalemate;

		reg inCheck;
		reg hasAnyLegal;

		begin
			stalemate = 1'b0;
			
			isChecked(!isBlackMove, inCheck);
			if (!inCheck) begin
				hasLegalMoves(!isBlackMove, hasAnyLegal);
				stalemate = !hasAnyLegal;
			end

		end
	endtask

	// -----------------------------------------------------------------------------------------------------------------

	reg [6:0] currSquare = 7'b0;
	reg [2:0] currRow = 3'b0;
	reg [2:0] currColumn = 3'b0;

	reg [6:0] nextSquare = 7'b0;
	reg [2:0] nextRow = 3'b0;
	reg [2:0] nextColumn = 3'b0;

	wire [3:0] hoveredPiece = pieceIsSelected ? board[nextSquare] : board[currSquare];
	reg previousSelect = 1'b0;
	reg pieceIsSelected = 1'b0; // toggles between specifying currSquare and nextSquare

	reg [63:0] legalMoves;
	reg isBlackMove = 1'b0;

	reg [25:0] clockDivider = 0;
	reg [9:0] player1Timer = 10'd600;
	reg [9:0] player2Timer = 10'd600;
	wire hold = SW[6];
	reg holdPosition = 1'b0; // might delete later; not used rn

	reg checkmate = 1'b0;
	reg stalemate = 1'b0;
	reg gameEnd = 1'b0;

	always @(posedge clock) begin
		if (reset) begin
			initialiseBoard();
			player1Timer <= 10'd600;
			player2Timer <= 10'd600;
			clockDivider <= 1'b0;
			isBlackMove <= 1'b0;
			previousSelect <= 1'b0;
			pieceIsSelected <= 1'b0;
			currSquare <= 7'b0;
			currRow <= 3'b0;
			currColumn <= 3'b0;
			nextSquare <= 7'b0;
			nextRow <= 3'b0;
			nextColumn <= 3'b0;
			checkmate <= 1'b0;
			stalemate <= 1'b0;
			gameEnd <= 1'b0;
			holdPosition <= 1'b0;
		end

		else begin 
			previousSelect <= select;

			if (!holdPosition && !hold && !gameEnd) begin
				if (select && !previousSelect) begin
					
				
					if (pieceIsSelected) begin
						nextRow = 1 * SW[0] + 2 * SW[1] + 4 * SW[2];
						nextColumn = 1 * SW[3] + 2 * SW[4] + 4 * SW[5];
						nextSquare = nextColumn * 8 + nextRow;
						
						if (nextRow == currRow && nextColumn == currColumn) begin
							nextRow = 3'd0;
							nextColumn = 3'd0;
							nextSquare = 6'b0;
							pieceIsSelected = 1'b0;
						end

						else if (isInsideBoard(nextRow) && isInsideBoard(nextColumn) && 
								(board[nextSquare] == 5'd0 || isWhitePiece(nextSquare) == isBlackMove)) begin
							computeLegalMoves(currSquare, legalMoves);

							if (legalMoves[nextSquare] != 0) begin
								board[nextSquare] = board[currSquare];
								board[currSquare] = 5'd0;

								isCheckmate(isBlackMove, checkmate);
								isStalemate(isBlackMove, stalemate);
								if (checkmate || stalemate) gameEnd <= 1'b1;

								pieceIsSelected <= 1'b0;
								isBlackMove <= !isBlackMove;
							end
						end
					end

					else begin
						currRow = 1 * SW[0] + 2 * SW[1] + 4 * SW[2];
						currColumn = 1 * SW[3] + 2 * SW[4] + 4 * SW[5];
						currSquare = currColumn * 8 + currRow;
						
						if (isInsideBoard(currRow) && isInsideBoard(currColumn) && 
							(board[currSquare] != 5'd0 && isWhitePiece(currSquare) != isBlackMove)) begin
							pieceIsSelected = 1'b1;
						end
							
					end
				end
			end
		
			if (!holdPosition && !hold && !gameEnd) begin
				if (player1Timer == 0 || player2Timer == 0) gameEnd <= 1'b1;

				else if (clockDivider >= 49_999_999) begin
					clockDivider <= 0;

					if (isBlackMove) player2Timer <= player2Timer - 1;
					else player1Timer <= player1Timer - 1;
				end

				else clockDivider <= clockDivider + 1;
			end
		end
	end
	displayRowAndColumn nextColumn (.value(nextColumn), .display(hex0Display));
	displayRowAndColumn nextRow (.value(nextRow), .display(hex1Display));
	displayRowAndColumn currColumnDisplay(.value(currRow), .display(hex2Display));
	displayRowAndColumn currRowDisplay(.value(currColumn), .display(hex3Display));
	displayPiece piece(.value(hoveredPiece), .display(hex4Display));
	displayTurn turn(.value(isBlackMove), .display(hex5Display));
endmodule