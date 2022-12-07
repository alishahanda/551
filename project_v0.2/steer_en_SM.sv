module steer_en_SM(clk,rst_n,tmr_full,sum_gt_min,sum_lt_min,diff_gt_1_4,
                   diff_gt_15_16,clr_tmr,en_steer,rider_off);

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input tmr_full;			// asserted when timer reaches 1.3 sec
  input sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  input sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight

  /////////////////////////////////////////////////////////////////////////////
  // HEY HOFFMAN...you are a moron.  sum_gt_min would simply be ~sum_lt_min. 
  // Why have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's weight is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  input diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in intitial state when waiting for sum_gt_min
  
  // You fill out the rest...use good SM coding practices ///
  typedef enum logic [1:0] {INIT, RIDER_ON_WAIT_1p3s, STEER_EN} state_t;
  state_t state, nxt_state;
  
  //On reset, assign state with INIT otherwise assign state with nxt_state value
  always_ff@(posedge clk, negedge rst_n) 
	if (!rst_n)
		state <= INIT;
	else 
		state <= nxt_state;
   
  always_comb begin
	//initialize default values for nxt_state and output signals
	en_steer = 0;
	rider_off = 1;
	clr_tmr = 0;
	nxt_state = INIT;
	
	case (state)
		//initial state --> wait here until rider is on the segway (i.e. sum_gt_min = 1)
		INIT: 
			if(sum_gt_min) begin
				nxt_state = RIDER_ON_WAIT_1p3s;
				rider_off = 0;
				clr_tmr = 1;
			end
			else begin
				nxt_state = INIT;
				rider_off = 1;
			end
				
		RIDER_ON_WAIT_1p3s: begin
			//transitioned to this wait state when diff_gt_15_16 was asserted 
			//hence wait to see if rider regains balance or completely steps off in which case we need to go back to INIT state
			if (sum_lt_min) begin
				nxt_state = INIT;
				rider_off = 1;
			end
			//need to wait and see if diff has been consistently below 1/4 of the sum for 1.3sec
			//If diff becomes greater than 1/4 (i.e. diff_gt_1_4 = 1) then we need to clear the timer
			else if (diff_gt_1_4) begin 
				nxt_state = RIDER_ON_WAIT_1p3s;
				clr_tmr = 1;
				rider_off = 0;
			end
			//Check if timer is full, i.e. 1.3sec have passed, then transition to STEER_EN state
			else if (tmr_full) begin
				nxt_state = STEER_EN;
				en_steer = 1;
				rider_off = 0;
			end
			else begin
				nxt_state = RIDER_ON_WAIT_1p3s;
				rider_off = 0;
			end
		end
		
		
		STEER_EN: begin
			if (sum_lt_min) begin  //check if rider fell off and transition to INIT state
				nxt_state = INIT;
				rider_off = 1;
			end
			else if (diff_gt_15_16) begin //check if rider has stepped off, transition to RIDER_ON_WAIT_1p3s state to see if rider achieves balance or completely steps off
				nxt_state = RIDER_ON_WAIT_1p3s;
				clr_tmr = 1;
				rider_off = 0;
			end			
			else begin
				nxt_state = STEER_EN;
				rider_off = 0;
				en_steer = 1; //en_steer is asserted when in STEER_EN state
			end
		end
				
		default:
			nxt_state = INIT;
			
	endcase
	
  end 
  
endmodule