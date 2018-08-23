package FIFO;

interface FIFO#(type element_type);
   method element_type first();
   method Action enq(element_type v);
   method Action deq();
   method Action clear();
endinterface

module mkFIFO(FIFO#(element_type)) provisos (Bits#(element_type, esz));
   Reg#(element_type) v <- mkRegU();
   Bit#(1) initialValid = 0;
   Reg#(Bit#(1)) valid <- mkReg(initialValid);
   method element_type first() if (valid == 1); 
      element_type result = v;
      return result;
   endmethod
   method Action enq(element_type new_v) if (valid == 0);
      v <= new_v;
      valid <= 1;
   endmethod
   method Action deq() if (valid == 1);
      valid <= 0;
   endmethod
   method Action clear();
      valid <= 0;
   endmethod
endmodule
module mkLFIFO(FIFO#(element_type)) provisos (Bits#(element_type, esz));
   Reg#(element_type) v <- mkRegU();
   Bit#(1) initialValid = 0;
   Reg#(Bit#(1)) valid <- mkReg(initialValid);
   method element_type first() if (valid == 1); 
      element_type result = v;
      return result;
   endmethod
   method Action enq(element_type new_v) if (valid == 0);
      v <= new_v;
      valid <= 1;
   endmethod
   method Action deq() if (valid == 1);
      valid <= 0;
   endmethod
   method Action clear();
      valid <= 0;
   endmethod
endmodule
module mkFIFO1(FIFO#(element_type));
   Reg#(element_type) v <- mkRegU();
   Bit#(1) initialValid = 0;
   Reg#(Bit#(1)) valid <- mkReg(initialValid);
   method element_type first() if (valid == 1); 
      return v;
   endmethod
   method Action enq(element_type new_v) if (valid == 0);
      v <= new_v;
      valid <= 1;
   endmethod
   method Action deq() if (valid == 1);
      valid <= 0;
   endmethod
   method Action clear();
      valid <= 0;
   endmethod
endmodule

module mkSizedFIFO#(Integer n)(FIFO#(element_type));
   Reg#(element_type) v <- mkRegU();
   Bit#(1) initialValid = 0;
   Reg#(Bit#(1)) valid <- mkReg(initialValid);
   method element_type first() if (valid == 1); 
      return v;
   endmethod
   method Action enq(element_type new_v) if (valid == 0);
      v <= new_v;
      valid <= 1;
   endmethod
   method Action deq() if (valid == 1);
      valid <= 0;
   endmethod
   method Action clear();
      valid <= 0;
   endmethod
endmodule

endpackage

