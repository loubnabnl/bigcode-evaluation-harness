# Evaluation & Submission guide for The Multilingual Code Evaluation LeaderBoard
This is a guide to reproduce the numbers in the [Multilingual Code Evaluation LeaderBoard](https://huggingface.co/spaces/bigcode/multilingual-code-evals).
The LeaderBoard is a demo for evaluating and comparing the performance of language models on code generation tasks.

The LeaderBoard is open for submissions of results produced by the community. If you have a model that you want to submit results for, please follow the instructions below.

## Running the evaluation
The leaderbord reports the passs@1 for [HumanEval](https://huggingface.co/datasets/openai_humaneval) Python benchamrk and some languages from the [MultiPL-E](https://huggingface.co/datasets/nuprl/MultiPL-E) benchmark. We use the same template and parameters for all models.

### Installation
Follow the setup instruction in the evaluation harness [README](https://github.com/bigcode-project/bigcode-evaluation-harness/tree/main#setup).

Create two folders `generations_$model` and `metrics_$model` to save the generated solutions and metrics for each task for your model.

To run the evaluation, we first generate the code solutions for a target model on all tasks on GPUs, then execute the code on a docker container.

### Generation
Below are the instruction for generating the code solutions sequentially or in parallel with slurm.
```
multiple_langs=(py js java cpp swift php d jl lua r rkt rb rs)

model=YOUR_MODEL
org=HF_ORGANISATION

for lang in "${langs[@]}"; do
    echo "Running multiple-$lang"
    generations_path=generations_$model/generations_$task_$model.json
    # if language is py we use HumanEval instead of MultiPL-Py benchmark
    if [ "$lang" == "py" ]; then
        task=humaneval
    else
        task=multiple-$lang
    fi
    accelerate launch main.py \
            --model $org/$model \
            --task task \
            --n_samples 50 \
            --batch_size 50 \
            --max_length_generation 512 \
            --temperature 0.2 \
            --precision bf16 \
            --trust_remote_code \
            --use_auth_token \
            --generation_only \
            --save_generations_path $generations_path
    echo "Task $task done"
done
```
This will generate and save the code solutions for all tasks in the `generations_$model` folder.

If you want to submit jobs in parallel with `slurm`, run multiple-eval.slurm with:
```
multiple_langs=(py js java cpp swift php d jl lua r rkt rb rs)

model=YOUR_MODEL
org=HF_ORGANISATION
out_path=generations_$model

for lang in "${langs[@]}"; do
    if [ "$lang" == "py" ]; then
        task=humaneval
    else
        task=multiple-$lang
    fi
    echo "Submitting task $task"
    sbatch -J "eval-$model-$task" /fsx/loubna/code/bigcode-evaluation-harness/multiple_evals.slurm "$model" "$task" "$org" "$out_path"
done
```
This will submit one job for each task.

### Execution

We execute and evaluate the solutions inside a docker container, you can either build the image or pull the one we provide:
```
# to build it:
# sudo make DOCKERFILE=Dockerfile-multiple all
sudo docker pull ghcr.io/bigcode-project/evaluation-harness-multiple
sudo docker tag ghcr.io/bigcode-project/evaluation-harness-multiple evaluation-harness-multiple
````

Then, you can run the evaluation on the generated code:
```
multiple_langs=(py js java cpp swift php d jl lua r rkt rb rs)

model=YOUR_MODEL
org=HF_ORGANISATION
#adapt to your generations/metrcis folder
generations_path=generations_$model
metrics_path=metrics_$model

for lang in "${langs[@]}"; do
    suffix=generations_$task_$model.json
    echo "Evaluation of $model on $lang benchmark, data in $suffix"
    if [ "$lang" == "py" ]; then
        task=humaneval
    else
        task=multiple-$lang
    fi
    sudo docker run -v $generations_path/$suffix:/app/$suffix:ro  -v $metrics_path:$metrics_path -it evaluation-harness-multiple python3 main.py \
        --model $org/$model \
        --tasks task \
        --load_generations_path /app/$suffix \ 
        --metric_output_path $metrics_path/metric_$task_$model.json \
        --allow_code_execution  \
        --use_auth_token \
        --temperature 0.2 \
        --n_samples 50 | tee -a logs_$model.txt
    echo "Task $task Done"
done
```

## Submission of results to the LeaderBoard
If you followed the steps above you now have a folder `metrics_$model` with `json` files, each containing the result of one task. To submit the results to the LeaderBoard, you need to create a csv with the metrics using `convert_jsons_to_csv.py` and submit it [here](https://huggingface.co/spaces/bigcode/multilingual-code-evals).
```
python convert_jsons_to_csv.py --metrics_path metrics_$model --output_path metrics_$model.csv
```
For credibility, we also invite you to uploade the generations and jsons to a HF dataset and posting the link in your submission.

Create a dataset on the hub, clone it, move the `generations_$model` and `metrics_$model` inside and push 🥳
```bash
# create YOUR_DATASET on the hub & clone it
git clone https://huggingface.co/datasets/$YOUR_DATASET
cp -r generations_$model $YOUR_DATASET
cp -r metrics_$model $YOUR_DATASET
cd YOUR_DATASET & git add . & git comit -am 'add data' & git push
```
