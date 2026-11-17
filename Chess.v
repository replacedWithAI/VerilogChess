module translateSWToDigit();

endmodule


module Chess(
	input [6:0] SW,
	input clock,
	input reset,
	input select
);
	reg [4:0] chessBoard[63:0];

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
		a2 = 9, b2 = 9. Right and up until h8 = 63
	*/
	task initialiseBoard;
		begin
			board[0] = 5'd2;
			board[1] = 5'd3;
			board[2] = 5'd4;
			board[3] = 5'd5;
			board[4] = 5'd6;
			board[5] = 5'd4;
			board[6] = 5'd3;
			board[7] = 5'd2;
			
			for (i = 0; i < 7; i = i + 1) begin
				board[i + 8] = 5'd1;
			end
			
			for (i = 0; i < 7; i = i + 1) begin
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

	function isInsideBoard;
		input reg signed [5:0] boardDimension;
		begin
			 isInsideBoard = (boardDimension >= 0 && boardDimension < 64);
		end
	endfunction

	task clearReachableSquares;
		output reg [63:0] reachable;
		begin
			reg[7:0] i;
			for (i = 0; i < 64; i = i+1)
				reachable[i] = 1'b0;
		end
	endtask


	task canLandOnSquare;
		input reg [5:0] currSquare;
		input reg signed [4:0] relativeNextRow;
		input reg signed [4:0] relativeNextColumn;
		inout reg reachable;
		output reg blocked;

		reg signed [5:0] currSquareRow; // board dimensions are always positive, but the code might enter negatives
		reg signed [5:0] currSquareColumn;
		reg isWhite;
		reg signed[4:0] nextRow;
		reg signed[4:0] nextColumn;
		reg signed[7:0] nextSquare;

		begin
			currSquareColumn = currSqure / 8;
			currSquareRow = currSquare % 8;
			isWhite = (board[currSquare] <= 5'd6);

			nextColumn = currSquareColumn + relativeNextColumn;
			nextRow = nextRow + relativeNextRow;

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
		output reg [63:0] reachable;
		
		begin
			computeSlidingReachableSquares(startSquare, 1, 0, board, reachable);
			computeSlidingReachableSquares(startSquare, 0, 1, board, reachable);
			computeSlidingReachableSquares(startSquare, -1, 0, board, reachable);
			computeSlidingReachableSquares(startSquare, 0, -1, board, reachable);
		end
	endtask


	task canReachDiagonally;
		input reg [6:0] currSquare;
		output reg [63:0] reachable;
		
		begin
			computeSlidingReachableSquares(startSquare, 1, 1, board, reachable);
			computeSlidingReachableSquares(startSquare, 1, -1, board, reachable);
			computeSlidingReachableSquares(startSquare, -1, 1, board, reachable);
			computeSlidingReachableSquares(startSquare, -1, -1, board, reachable);
		end
	endtask


	task knightCanReach;
		input reg [6:0] currSquare;
		output reg [63:0] reachable;
		
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

	// knight and pawn are the only pieces that have unique logic, and king for castling
	task pawnCanReach;
		input reg [5:0] currSquare;
		inout reg [63:0] reachable;
		
		reg signed [4:0] currRow;
		reg signed [4:0] currColumn;
		reg isWhite;
		reg signed [1:0] forwardDirection;
		reg [3:0] startingColumn;
		reg signed [4:0] nextRow;
		reg signed [4:0] nextColumn;
		reg signed [1:0] diagonalSquareRow; 
		reg signed [7:0] nextSquare;

		begin
			currColumn = currSquare / 8;
			currRow = currSquare % 8;
			isWhite = (board[currSquare] <= 4'd6);
			forwardDirection = isWhite ? 1 : -1;
			startingColumn = isWhite ? 1 : 6;
			nextColumn = currRow + forwardDirection;

			if (isInsideBoard(nextColumn)) begin
				nextSquare = currSquare + nextColumn * 8;

				if (board[nextSquare] == 5'd0) begin
					reachable[nextSquare] = 1'b1;

					if (currColumn == startingColumn) begin
						nextSquare = nextSquare + forwardDirection * 8;
						reachable[nextSquare] = board[nextSquare] == 5'd0 ? 1'd1 : 1'd0;
					end
				end

				for (diagonalSquareRow = -1; diagonalSquareRow <= 1; diagonalSquareRow = diagonalSquareRow + 2) begin
					nextRow = currRow + diagonalSquareRow;
					if (isInsideBoard(nextRow) && (board[nextColumn * 8 + nextRow] <= 5'd6) != isWhite)
						reachable[nextColumn * 8 + nextRow] == 1'b1;
					end
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
		input reg isBlackTurn;
		inout reg isAttacked;

		reg signed [4:0] i;
		reg signed [4:0] currRow;
		reg signed [4:0] currColumn;
		reg signed [4:0] nextRow;
		reg signed [4:0] nextColumn;
		reg [4:0] piece;
		reg [5:0] pieceSquare;
		reg [4:0] pieceType;
		reg isDiagonal;

		begin
			currRow = currSquare % 8;
			currColumn = currColumn / 8;
			piece = 5'd0;

			for (i = 1; i < 8; i = i + 1) begin
				nextRow = currRow + i * rowDirection;
				nextColumn = currColumn + i * columnDirection;

				if (piece == 5'd0 && isInsideBoard(nextRow) && isInsideBoard(nextColumn) && board[nextColumn * 8 + nextRow] != 5'd0)
					begin
					piece = board[nextColumn * 8 + nextRow];
					pieceSquare = nextColumn * 8 + nextRow;
				end
			end

			if (piece != 5'd0 && (piece >= 5'd1 && piece <= 5'd6) == isBlackTurn) begin
				pieceType = pieceType - isBlackTurn * 6;
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
		output reg isAttacked;

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
			kingPiece = 5'd6 - isBlackTurn * 6;
			for (i = 0; i < 64; i = i + 1) begin
				if (board[i] == kingPiece)
					kingSquare = i;
					kingFound = 1'b1;
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
		reg signed [1:0] k;
		reg signed [1:0] pawnDirection;

		begin : checked
			checked = 1'b0;
			
			findKing(!isBlackTurn, kingSquare, found);
			if (!found) disable checked;

			for (i = -1; i <= 1; i = i + 1) begin // queen, bishop, rook attack
				for (j = -1; j <= 1; j = j + 1) begin

				if (i != 1'b0 && j != 1'b0)
					getFirstPieceInDirection(kingSquare, i, j, isBlackTurn, checked);

				end
			end

			i = 3'b0;
			j = -3'd1;
			attackingPieceType = isBlackTurn ? 5'd3 : 5'd9;

			for (i = 1; i <= 2; i = i + 1) begin // knight attack
				for (k = -1; k <= 1; k = k + 2) begin
					
					getPieceByFixedOffset(kingSquare, i * k, (i + 1) * j, attackingPieceType, checked);
					j = -j;

				end
			end

			i = 3'b0;
			j = 3'd0;
			attackingPieceType = isBlackTurn ? 5'd6 : 5'd12;

			// pretty unintuitive because this checks if a king is adjacent to an enemy king, obviously illegal
			// but this task checks if the king's square is safe, ignoring how it got there. So this is necessary
			for (i = -1; i <= 1; i = i + 1) begin 
				for (j = -1; j <= 1; j = j + 1) begin

				if (i != 1'b0 && j != 1'b0)
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

		begin
			movedPiece = board[currSquare];
			capturedPiece = board[targetSquare];
			isWhite = (movedPiece >= 5'd1 && movedPiece <= 5'd6);

			board[targetSquare] = board[currSquare];
			board[currSquare] = 5'd0;
			isChecked(!isWhite, isSafeMove);

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

	task hasLegalMoves
		input reg isBlackMove;
		output reg hasAnyLegal;

		reg [6:0] i;
		reg [63:0] legalMoves;

		begin : checkForMoves
			hasAnyLegal = 1'b0;

			for (i = 0; i < 64; i = i + 1) begin

				if (board[i] != 5'd0 && (board[i] >= 5'd7 && board[i] <= 5'd12) == isBlackMove) begin
					commputeLegalMoves(i, legalMoves);

					if (legalMoves != 64'b0) begin
						hasAnyLegal = 1'b1;
						disable checkForMoves;
					end
					
				end

			end
		end
	endtask

	task isCheckmate
		input reg isBlackMove;
		output reg checkmate;

		reg inCheck;
		reg hasAnyLegal;

		begin
			checkmate = 1'b0;

			isChecked(isBlackMove, inCheck);
			if (isChecked) begin
				hasLegalMoves(isBlackMove, hasAnyLegal);
				checkmate = !hasAnyLegal;
			end
		
		end
	endtask

	task isStalemate
		input reg isBlackMove;
		output reg stalemate;

		reg inCheck;
		reg hasAnyLegal;

		begin
			stalemate = 1'b0;
			
			isChecked(isBlackMove, inCheck);
			if (!isChecked) begin
				hasLegalMoves(isBlackMove, hasAnyLegal);
				checkmate = !hasAnyLegal;
			end

		end
	endtask

	// -----------------------------------------------------------------------------------------------------------------

	reg [6:0] currSquare;
	reg [2:0] currRow;
	reg [2:0] currColumn;

	reg [6:0] nextSquare;
	reg [2:0] nextRow;
	reg [2:0] nextColumn;

	reg previousSelect;
	reg pieceIsSelected;
	reg nextSelect; // toggles between specifying currSquare and nextSquare

	reg [63:0] legalMoves;
	reg isBlackMove;

	reg [25:0] clockDivider = 0;
	reg [9:0] player1Timer;
	reg [9:0] player2Timer;
	wire hold = SW[6];
	reg holdPosition;

	reg checkmate;
	reg stalemate;
	reg gameEnd;

	always @(posedge clock) begin
		previousSelect <= select;
		
		if (holdPosition || hold || gameEnd)

		else if (select && !previousSelect)
			pieceIsSelect = !pieceIsSelect;
		
		else if (pieceIsSelected && !(select && !previousSelect) && nextSelect) begin
			nextRow <= 1 * SW[0] + 2 * SW[1] + 4 * SW[2];
			nextColumn <= 1 * SW[3] + 2 * SW[4] + 4 * SW[5];
			
			if (isInsideBoard(nextRow) && isInsideBoard(nextColumn)) begin
				nextSquare <= nextColumn * 8 + nextRow;
				computeLegalMoves(currSquare legalMoves);

				if (legalMoves[nextSquare] != 0) begin
					board[nextSquare] <= board[currSquare];
					board[currSquare] <= 5'd0;

					isCheckmate(isBlackMove, checkmate);
					isStalemate(isBlackMove, stalemate);
					if (checkmate || stalemate) gameEnd <= 1'b1;
				end

				nextSelect <= ~nextSelect;
			end

		else if (pieceIsSelected && !(select && !previousSelect)) begin
			currRow <= 1 * SW[0] + 2 * SW[1] + 4 * SW[2];
			currColumn <= 1 * SW[3] + 2 * SW[4] + 4 * SW[5];
			
			if (isInsideBoard(currRow) && isInsideBoard(currColumn)) begin
				currSquare <= column * 8 + row;
				nextSelect <= 1'b1;
			end
		
		else if (player1Timer == 0 || player2Timer == 0)
			gameEnd <= 1'b1;
	
		else if (clockDivider >= 50000000)
			 if (isBlackMove) player2Timer <= player2Timer - 1;
			 else player1Timer <= player1Timer - 1;
			 clockDivider <= 0;
		end

		else clockDivider <= clockDivider + 1;
	end
endmodule