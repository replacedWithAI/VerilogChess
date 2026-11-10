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
			5: white king
			6: white queen:
			7-12: black pawn to black queen
			
		also, a1 = 0, b1 = 1, and so on so forth across the row, then
		a2 = 9, b2 = 9. Right and up until h8 = 63
	*/
	task initialiseBoard
		input reset,
		input clock,
		output reg [11:0] board[63:0]
		
		begin
			board[0] = 5'd2;
			board[1] = 5'd3;
			board[2] = 5'd4;
			board[3] = 5'd5;
			board[4] = 5'd6;
			board[5] = 5'd4;
			board[6] = 5'd3;
			board[7] = 5'd2;
			
			for (i = 1; i <= 8; i = i + 1) begin
				board[i + 8] = 5'd1;
			end
			
			for (i = 1; i <= 8; i = i + 1) begin
				board[i + 6 * 8) = 5'd7;
			end
			
			board[56] = 5'd8;
			board[57] = 5'd9;
			board[58] = 5'd10;
			board[59] = 5'd11;
			board[60] = 5'd12;
			board[61] = 5'd10;
			board[62] = 5'd9;
			board[63] = 5'd8;
					
			for (i = 2; i < 7; i = i + 1) begin
				for (j = 0; j < 8; j = j + 1) begin
					board[i * 8 + j] = 5'd0;
				end
			end
		end
	endtask;
	
	task canReachVerticallyHorizontally
		input currSquare;
		input targetSquare;
		output board [11:0] board[63:0];
		output canReach;
		
		begin : tryReach
			reg[2:0] currSquareRow = currSquare % 8;
			reg[2:0] currSquareColumn = currSquare / 8;
			reg[2:0] targetSquareRow = targetSquare % 8;
			reg[2:0] targetSquareColumn = targetSquare / 8;
			
			if (targetSquare > 63 || targetSquare < 0) begin
				canReach = 1'd0;
				disable tryReach;
			end
			
			// moving vertically
			if (currSquareRow != targetSquareRow && currSquareColumn == targetSquareColumn) begin
				
				reg[6:0] i;
				reg signed [1:0] traversal = targetSquareRow < currSquareColumn ? 1 ; -1;				
				for (i = currSquareRow + traversal; i != targetSquareRow; i = i+traversal) begin
					if (board[i] != 0) begin // this piece type can't move through allies or enemies
						canReach = 1'd0;
						disable tryReach;
					end
				end
				
				canReach =  1'd1;
				board[targetSquare] = board[currSquare];
				board[currSquare] = 0;
			end
			
			// moving horizontally
			else if (currSquareRow == targetSquareRow && currSquareColumn != targetSquareColumn) begin
			
				reg[6:0] i;
				reg signed [1:0] traversal = targetSquareRow < currSquareColumn ? 8 ; -8;
				for (i = currSquareRow + traversal; i != targetSquareRow; i = i+traversal) begin
					if (board[i] != 0) begin
						canReach = 1'd0;
						disable tryReach;
					end
				end
				
				canReach =  1'd1;
				board[targetSquare] = board[currSquare];
				board[currSquare] = 0;
			end
			
			else canReach =  1'd0;

		end
	endtask

	task canReachDiagonally
		input currSquare;
		input targetSquare;
		output reg [11:0] board[63:0];
		output canReach;
		
		begin : tryReach
			
			if (targetSquare > 63 || targetSquare < 0) begin
				canReach = 1'd0;
				disable tryReach;
			end
			
			// forward slash
			if (currSquare - targetSquare % 9 == 0) begin
				
				reg[6:0] i;
				reg signed [4:0] traversal = targetSquareRow < currSquareColumn ? 9 ; -9;				
				for (i = currSquareRow + traversal; i != targetSquareRow; i = i+traversal) begin
					if (board[i] != 0) begin
						canReach = 1'd0;
						disable tryReach;
					end
				end
				
				canReach =  1'd1;
				board[targetSquare] = board[currSquare];
				board[currSquare] = 0;
			end
			
			// back slash
			else if (currSquareRow - targetSquare % 7 == 0) begin
			
				reg[6:0] i;
				reg signed [3:0] traversal = targetSquareRow < currSquareColumn ? 7 ; -7;
				for (i = currSquareRow + traversal; i != targetSquareRow; i = i+traversal) begin
					if (board[i] != 0) begin 
						canReach = 1'd0;
						disable tryReach;
					end
				end
				
				canReach =  1'd1;
				board[targetSquare] = board[currSquare];
				board[currSquare] = 0;
			end
			
			else canReach =  1'd0;

		end
	endtask

	task computeKnightMove(
	);
		
	endtask
	
	
	always @(posedge clock) begin
			if (select)
		
		
endmodule

task computePinnedPieces(
);
endtask

/*
	Moving in chess is the most difficult task (besides solving it)
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
