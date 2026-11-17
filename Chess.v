module translateSWToDigit();

endmodule


module Chess(
	input [5:0] SW,
	input clock,
	input reset,
	input select,
	output [6:0] HEX5,
	output [6:0] HEX3,
	output [6:0] HEX1,
	output [6:0] HEX0
);
	reg [4:0] chessBoard[63:0];
	reg [2:0] row;
	reg [2:0] column;
	

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
		input reset;
		input clock;
		
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
		input[5:0] currSquare;
		input signed [4:0] relativeNextRow;
		input signed [4:0] relativeNextColumn;
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
		input signed [5:0] rowDirection;
		input signed [5:0] columnDirection;
		input[4:0] board [63:0];
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
		input [6:0] currSquare;
		output reg [63:0] reachable;
		
		begin
			computeSlidingReachableSquares(startSquare, 1, 0, board, reachable);
			computeSlidingReachableSquares(startSquare, 0, 1, board, reachable);
			computeSlidingReachableSquares(startSquare, -1, 0, board, reachable);
			computeSlidingReachableSquares(startSquare, 0, -1, board, reachable);
		end
	endtask


	task canReachDiagonally;
		input [6:0] currSquare;
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
		input[5:0] currSquare;
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
		input[5:0] currSquare;
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
		input[5:0] currSquare;
		input signed [5:0] rowDirection;
		input signed [5:0] columnDirection;
		input isBlackTurn;
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
		input[5:0] currSquare;
		input signed [5:0] rowDirection;
		input signed [5:0] columnDirection;
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
		input isBlackTurn;
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
		input isBlackTurn;
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
		input[5:0] currSquare;
		input[5:0] targetSquare;
		output reg isSafeMove;

		reg [4:0] movedPiece;
		reg [4:0] capturedPiece;
		reg isWhite;
		reg isChecked;

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
		input [5:0] currSquare;
		output reg[63:0] legalMoves;

		reg[63:0] reachable;
		reg[6:0] i;
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
		input isBlackMove;
		output reg hasAnyLegal;

		reg[6:0] i;
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
		input isBlackMove;
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
		input isBlackMove;
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
	
	always @(posedge clock) begin
			if (select)
		
		
endmodule

task computePinnedPieces(
);
endtask

/*
	I differentiate "possible" from "legal" because computing "legal" entails:
		- Making sure the piece isn't pinned
		- Making sure the king isn't in check
	These require computing other piece's moves, as opposed to "possible" that only need their positions
*/
task computePossibleMoves
	input clock;
	input select;
	output reg [4:0] chessBoard [63:0];
endtask

task isChecked(
);

endtask

task isCheckmate(
);

endtask
