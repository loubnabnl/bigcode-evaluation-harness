#echo small test run on 4 tasks
#accelerate launch  --config_file /beh/accelerate_cfg.yaml main.py   --output_path /repo_workdir/evaluation_results_test.json --tasks mbpp   --prompt_type_mbpp "incoder" --allow_code_execution=True --evaluation_only True   --model codeparrotdedup-08  --num_tasks_mbpp 4

echo running evaluation on all 500 tasks
accelerate launch   --config_file /beh/accelerate_cfg.yaml main.py  --output_path /repo_workdir/evaluation_results.json --tasks mbpp   --prompt_type_mbpp "incoder" --allow_code_execution=True --evaluation_only True   --model codeparrotdedup-08
