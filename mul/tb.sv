`include "uvm_macros.svh"
import uvm_pkg::*;

//////////////////////////////
//  Class: tarnsaction extends uvm_sequence_item
class tarnsaction_packet extends uvm_sequence_item;
    ``uvm_object_utils(tarnsaction_packet)
    
    //  Group: Variables
    rand bit [3:0] a;
    rand bit [3:0] b;
         bit [7:0] y;

    //  Constructor: new
    function new(input string path = "tarnsaction_packet");
        super.new(path);
    endfunction: new

endclass: tarnsaction_packet
///////////////////////////////
//  Class: generator
class generator extends uvm_sequence#(generator);
    `uvm_object_utils(generator)

    //  Group: hooks is like an object of a class in c
        tarnsaction tr;

    //  Constructor: new
    function new(input string path = "generator");
        super.new(path);
    endfunction: new

    //  Task: body
    //  This is the user-defined task where the main sequence code resides.
    virtual task body();
        repeat(15);
            begin
                tr = tarnsaction::type_id::create("tr"); // create the object
                start_item(tr); // askign the sequencer for a new data packet
                assert(tr.randomize()); // generates random values for instances of tr
                `uvm_info("SEQ", $sformatf("a : %0d b : %0d y : %0d", tr.a, tr.b, tr.y ), UVM_NONE);
                finish_item(tr);
                
            end    
    endtask   
endclass: generator
///////////////////////////////////
//  Class: drv
class drv extends uvm_driver#(tarnsaction);
    `uvm_component_utils(drv);

    //  hooks:
    tarnsaction tr;
    virtual mul_if mif;

    //  Constructor: new
    function new(inout string path = "drv", uvm_component parent = null);
        super.new(path, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual mul_if)::get(this, "", "mif", mif)) // accessing the virtual interface 
            `uvm_error("drv", "unable to access interface"); // if couldnt access th einterface throw an error
    endfunction: build_phase

    //  Function: run_phase
    virtual task run_phase(uvm_phase phase);
        tr = tarnsaction::type_id::create("tr"); // calling th ecunstructor for tr 
            forever begin
                seq_item_port.get_next_item(tr);
                mif.a <= tr.a;
                mif.b <= tr.b;
                `uvm_info("DRV", $sformatf("a : %0d b : %0d y : %0d", tr.a, tr.b, tr.y ), UVM_NONE);
                seq_item_port.item_done(tr);
                #20;      
            end
    endtask
endclass: drv
///////////////////////////////////
//  Class: mon
class mon extends uvm_monitor;
    `uvm_component_utils(mon);

    uvm_analysis_port#(tarnsaction) send;
    tarnsaction tr;
    virtual mul_if mif;   

    //  Constructor: new
    function new(string name = "mon", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    /*---  UVM Build Phases            ---*/
    /*------------------------------------*/
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr = tarnsaction::type_id::create("tr");
        send = new("send", this);
        if(!uvm_config_db#(virtual mul_if)::get(this, "", "mif", mif))
            `uvm_error("DRV", "Unable to access interface")
    endfunction: build_phase

    /*---  UVM Run Phases              ---*/
    /*------------------------------------*/
    //  Function: start_of_simulation_phase
    virtual task void run_phase(uvm_phase phase);
        forever begin
        #20;
        tr.a = mif.a;
        tr.b = mif.b;
        tr.y = mif.y;
        `uvm_info("MON", $sformatf("a : %0d b : %0d c : %0d", tr.a, tr.b, tr.y ), UVM_NONE);
        send.write(tr);
        end
    endtask
endclass: mon
///////////////////////////////////
class sco extends uvm_scroeboard;
    `uvm_object_utils(sco)
    uvm_analysis_imp#(tarnsaction, sco) recv;
    
    function new(input string inst = "sco", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        recv = new("recv", this);
    endfunction

    virtual function void write(tarnsaction tr);
            if(tr.y == (tr.a * tr.b))
                `uvm_info("SCO", $sformatf("Test Passed -> a : %0d b : %0d y : %0d", tr.a, tr.b, tr.y ), UVM_NONE)
            else
                `uvm_info("SCO", $sformatf("Test Failed -> a : %0d b : %0d y : %0d", tr.a, tr.b, tr.y ))
        $display("-------------------------------------------------------");
    endfunction
endclass: sco
///////////////////////////////////
//  Class: agent
class agent extends uvm_agent;
    `uvm_component_utils(agent);
    //  Constructor: new
    function new(input string inst = "agent", uvm_component parent = null);
        super.new(inst, parent);
    endfunction: new

    drv d;
    uvm_sequencer#(tarnsaction) seqr;
    mon m;

    /*---  UVM Build Phases            ---*/
    /*------------------------------------*/
    //  Function: build_phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        d = drv::type_id::create("d", this);
        m = mon::type_id::create("mon", this);
        seqr = uvm_sequencer#(tarnsaction)::type_id::create("seqr", this);
    endfunction

    /*---  UVM connect Phases              ---*/
    /*------------------------------------*/
    //  Function: connect phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase); 
        d.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass: agent
///////////////////////////////////
