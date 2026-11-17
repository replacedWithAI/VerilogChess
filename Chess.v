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
	// compute squares that pieces can reach, assuming their king isn't checked

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
	
	// I don't know how to do this besides manually checking every possibility
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
