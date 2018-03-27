package GCD;

interface GCD#(type a);
    method Action set_n (a n);
    method Action set_m (a m);
    method a result;
endinterface: GCD

module mkGCD(GCD#(Bit#(32)));
   Reg#(Bit#(32)) n <- mkReg(0);
   Reg #(Bit#(32)) m <- mkReg(0);

   rule swap (n > m && m != 0);
      n <= m;
      m <= n;
   endrule

   rule sub (n <= m && m != 0);
      m <= m - n;
   endrule

   method Action set_n(Bit#(32) in_n) if (m == 0);
         n <= in_n;
   endmethod
   method Action set_m(Bit#(32) in_m) if (m == 0);
      action
         m <= in_m;
      endaction
   endmethod

   method Bit#(32) result() if (m == 0);
      return n;
   endmethod: result
endmodule: mkGCD

module mkMain(Empty);
   GCD#(Bit#(32)) gcd <- mkGCD();
   Reg#(Bit#(1)) started <- mkReg(0);
   Reg#(Bit#(32)) dv <- mkReg(0);
   rule rl_start if (started == 0);
      let _ <- gcd.set_n(100);
      let _ <- gcd.set_m(20);
      started <= 1;
   endrule
   rule rl_display;
      let v = gcd.result();
      dv <= v;
`ifndef BSVTOKAMI
      $finish();
`endif
   endrule
endmodule

endpackage: GCD
