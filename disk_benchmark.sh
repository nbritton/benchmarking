#!/bin/bash

nodes=".*kvm20[2-9].*";

reboot_nodes () {

	timer=0;

	test_nodes () {

		test_data=$(salt -E ${nodes} --timeout 1 test.ping | egrep -v ":|True" 1>/dev/null;)

		if [[ "${test_data}" == "" ]]; then
			return 0
		else
			return 1
		fi

	}

	salt -E ${nodes} --timeout 1 --async system.reboot 1>/dev/null;
	
	sleep 60;
	
	until test_nodes; do
		sleep 1;
		#let "timer++";
		#if [[ "${timer}" == "20" ]]; then
		#	echo "A timeout has occured.";
		#	exit 1;
		#fi
	done
	
	return 0

}

process_results () {
	
	calculate_results () {

		for wrcache in WT WB; do

			for rdcache in NoRA RA; do

				for iopolicy in Direct Cached; do

					for pdcache in Off On; do

						parameters="wrcache=${wrcache} rdcache=${rdcache} iopolicy=${iopolicy} pdcache=${pdcache}";

						printf "${wrcache}:${rdcache}:${iopolicy}:${pdcache} ";

						grep "${parameters}" ~/iozone_benchmark_results.txt | awk '{n=2; c6+=$6; c7+=$7; c8+=$8; c9+=$9; c10+=$10; c11+=$11; c12+=$12; c13+=$13; c14+=$14; c15+=$15; c16+=$16; c17+=$17; c18+=$18} END {print ((c6/n)+(c7/n)+(c11/n)+(c13/n)+(c15/n)+(c16/n))/6,((c8/n)+(c9/n)+(c10/n)+(c12/n)+(c14/n)+(c17/n)+(c18/n))/7}';

					done

				done

			done

		done

	}

	calculate_options () {

		options="wrcache=WT wrcache=WB rdcache=RA rdcache=NoRA iopolicy=Direct iopolicy=Cached pdcache=On pdcache=Off drop_caches=True drop_caches=False";

		for i in ${options}; do

			printf "${i}: ";

			#grep ${i} ~/iozone_benchmark_results.txt | awk '{sum+=$6;a[NR]=$6}END{for(i in a)y+=(a[i]-(sum/NR))^2;print sqrt(y/(NR-1))}';

			grep ${i} ~/iozone_benchmark_results.txt | awk '{n=16; c6+=$6; c7+=$7; c8+=$8; c9+=$9; c10+=$10; c11+=$11; c12+=$12; c13+=$13; c14+=$14; c15+=$15; c16+=$16; c17+=$17; c18+=$18} END {print ((c6/n)+(c7/n)+(c11/n)+(c13/n)+(c15/n)+(c16/n))/6,((c8/n)+(c9/n)+(c10/n)+(c12/n)+(c14/n)+(c17/n)+(c18/n))/7}' | tr -d "\n";

			# Simple average of the standard deviations
			#for j in $(seq 6 18); do grep "${i}" ~/iozone_benchmark_results.txt | awk -v col=${j} '{sum+=$col;a[NR]=$col}END{for(i in a)y+=(a[i]-(sum/NR))^2;print sqrt(y/(NR-1))}'; done | awk '{sum+=$1} END {print "%0.1f",sum/NR}';

			# https://en.wikipedia.org/wiki/Pooled_variance#Definition_and_computation
			for j in $(seq 6 18); do grep "${i}" ~/iozone_benchmark_results.txt | awk -v col=${j} '{sum+=$col;a[NR]=$col}END{for(i in a)y+=(a[i]-(sum/NR))^2;print y/(NR-1)}'; done | awk '{sum+=(15*$1)} END {print "%0.1f",sqrt(sum/195)}';

		done

	}

	calculate_aggregate () {

		cat - | awk '{printf $1}" "{printf "%10.1f",$2}" "{printf "%10.1f",$3}" "{printf "%10.1f\n",$2+$3}';

	}

	echo;

	echo "Options: Write(MB/s) Read(MB/s) W+R(MB/s):";

	calculate_results | calculate_aggregate | sort -rn -k 4,4 -k 2,2 -k 3,3 -k 1,1;

	echo;

	echo "Option: Write(MB/s): Read(MB/s) W+R(MB/s) STDEV:";

	calculate_options | awk '{printf $1}" "{printf "%10.1f",$2}" "{printf "%10.1f",$3}" "{printf "%10.1f",$2+$3}" "{printf "%10.1f\n",$4}';
}

run_tests () {
	for wrcache in WT WB; do

		for rdcache in NoRA RA; do

			for iopolicy in Direct Cached; do

				for pdcache in Off On; do

					reboot_nodes;

					parameters="wrcache=${wrcache} rdcache=${rdcache} iopolicy=${iopolicy} pdcache=${pdcache}";

					salt -E ${nodes} cmd.run "/opt/MegaRAID/perccli/perccli64 /c0 /v1 set ${parameters}" 1>/dev/null;

					salt -E ${nodes} cmd.run "/opt/MegaRAID/perccli/perccli64 /c0 /v2 set ${parameters}" 1>/dev/null;

					salt -E ${nodes} cmd.run "/opt/MegaRAID/perccli/perccli64 /c0 /v3 set ${parameters}" 1>/dev/null;

					salt -E ${nodes} cmd.run "/opt/MegaRAID/perccli/perccli64 /c0 /v4 set ${parameters}" 1>/dev/null;

					printf "${parameters} ";

					salt -E ${nodes} cmd.run 'seq 10 | xargs -I{} bash -c "iozone -a -g 16M -K -f /var/lib/libvirt/images/iozone; echo 3 > /proc/sys/vm/drop_caches;"' | awk '/^ *[0-9]/ {n=6480000; c3+=$3; c4+=$4; c5+=$5; c6+=$6; c7+=$7; c8+=$8; c9+=$9; c10+=$10; c11+=$11; c12+=$12; c13+=$13; c14+=$14; c15+=$15} END {print c3/n,c4/n,c5/n,c6/n,c7/n,c8/n,c9/n,c10/n,c11/n,c12/n,c13/n,c14/n,c15/n}';

					printf "${parameters} ";

					salt -E ${nodes} cmd.run 'seq 10 | xargs -I{} iozone -a -g 16M -K -f /var/lib/libvirt/images/iozone' | awk '/^ *[0-9]/ {n=6480000; c3+=$3; c4+=$4; c5+=$5; c6+=$6; c7+=$7; c8+=$8; c9+=$9; c10+=$10; c11+=$11; c12+=$12; c13+=$13; c14+=$14; c15+=$15} END {print c3/n,c4/n,c5/n,c6/n,c7/n,c8/n,c9/n,c10/n,c11/n,c12/n,c13/n,c14/n,c15/n}';

				done

			done

		done

	done

}

case $1 in

	"test")

		run_tests | tee ~/iozone_benchmark_results.txt;

	;;

	"results")

		echo;

		echo "Key: wrcache:rdcache:iopolicy:pdcache";

		process_results | column -te;

	;;

esac

exit 0;
