all:
	iverilog -g2005-sv -DICARUS=1 -o tb.qqq tb.v
	vvp tb.qqq >> /dev/null
wave:
	gtkwave tb.vcd
clean:
	rm -f *.rpt *.summary *.sof *.done *.pin *.qws *.bak *.smsg *.qws *.vcd \
		  *.qqq *.jic *.map *.qqq undo_redo.txt PLLJ_PLLSPE_INFO.txt
	rm -rf db incremental_db simulation timing output_files
