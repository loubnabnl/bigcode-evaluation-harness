<h1 align="center">Code Generation LM Evaluation Harness</h1>


<h4 align="center">
    <p>
        <a href="#features">Tasks</a> |
        <a href="#setup">Usage</a> |
        <a href="#implementing-new-tasks">Contribution</a> |
        <a href="#documentation">Documentation</a> |
        <a href="https://huggingface.co/bigcode">BigCode</a>
    <p>
</h4>

<h3 align="center">
    <img style="float: middle; padding: 10px 10px 10px 10px;" width="50" height="50" src="https://user-images.githubusercontent.com/44069155/191557209-6219acb8-a766-448c-9bd6-284d22b1e398.png" /></a>
</h3>

## Features

This is a framework to evaluate autoregressive code generation language models. This is a work in progress part of the BigCode project. We welcome contributions to fix issues, enhance features and add new benchmarks. You can find a contribution guide in [`CONTRIBUTING.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/CONTRIBUTING.md) and more documentation in [`docs/README.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/docs/README.md). 

Below are the features and tasks of this framework:

- Any autoregressive model available on [Hugging Face hub](https://huggingface.co/) can be used, but we recommend using code generation models trained specifically on Code such as [CodeParrot](https://huggingface.co/codeparrot/codeparrot), [InCoder](https://huggingface.co/facebook/incoder-6B) and [CodeGen](https://huggingface.co/Salesforce/codegen-16B-mono).
 - 3 code generation **Python** tasks (with unit tests): [HumanEval](https://huggingface.co/datasets/openai_humaneval), [APPS](https://huggingface.co/datasets/codeparrot/apps) and [MBPP](https://huggingface.co/datasets/mbpp).
- [CoNaLa](https://huggingface.co/datasets/neulab/conala) for **Python** code generation (2-shot setting and evaluation with BLEU score)
- [Spider](https://huggingface.co/datasets/spider) for **SQL** code generation (2-shot setting and evaluation with BLEU score)
- [Concode](https://huggingface.co/datasets/code_x_glue_tc_text_to_code) for **Java** code generation (2-shot setting and evaluation with BLEU score)
- Code to text task from [CodeXGLUE](https://huggingface.co/datasets/code_x_glue_ct_code_to_text) (zero-shot & fine-tuning) for 6 languages: **Python, Go, Ruby, Java, JavaScript and PHP.** 
- 3 multilingual downstream classification tasks: [Java Complexity prediction](https://huggingface.co/datasets/codeparrot/codecomplex), [Java code equivalence prediction](https://huggingface.co/datasets/code_x_glue_cc_clone_detection_big_clone_bench), [C code defect prediction](https://huggingface.co/datasets/code_x_glue_cc_defect_detection).

## Setup

```bash
git clone https://github.com/loubnabnl/bigcode-evaluation-harness.git
cd bigcode-evaluation-harness
```
Install [`torch`](https://pytorch.org/get-started/locally/) based on your device type and the other pacakges using:
```
pip install -r requirements.txt
```
Also make sure you have `git-lfs` installed and are logged in the Hub
```
huggingface-cli login
````

We use [`accelerate`](https://huggingface.co/docs/accelerate/index) to generate code/text in parallel when multiple GPUs are present (multi-GPU mode). You can configure it using:

```bash
accelerate config
```

If you are using the evaluation harness in an evaluation only mode, just use CPU when configuring accelerate in No distributed training mode. For this evaluation only mode, you can find the all these setup instructions in `setup.sh`. When evaluating on a machine whith many workers, you can get a Too many open files error increasing `ulimit` seems to fix this issue.
```
ulimit -n 50000
```

In `setup.sh` we included the code below to download MBPP generations (500 tasks) and run the evaluation.
```
cd ..
# download generations
git clone https://huggingface.co/datasets/loubnabnl/code-generations-bigcode
# move generations to evaluation harness
cp code-generations-bigcode/anylicense-02/generations.json bigcode-evaluation-harness/
# add --num_tasks_mbpp 4 to this command to test it works on 4 tasks
accelerate launch  main.py   --tasks mbpp   --prompt_type_mbpp "incoder" --allow_code_execution=True --evaluation_only True   --model gpt2-anyldedup-08  
```
## Usage

For details on how to evaluate on the tasks, please refer to the documentation in [`docs/README.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/docs/README.md). Below are some examples:

```bash
# to evaluate on HumanEval with pass@1, pass@10, pass@100
# (allow_code_execution is for executing the generated code: read the displayed warning)
accelerate launch  main.py \
  --model <MODEL_NAME> \
  --max_length_generation <MAX_LENGTH> \
  --tasks humaneval \
  --temperature 0.2 \
  --n_samples 200 \
  --batch_size 10 \
  --allow_code_execution=False 

# to evaluate your model on MBPP with pass@1
accelerate launch  main.py \
  --model <MODEL_NAME> \
  --max_length_generation <MAX_LENGTH> \
  --tasks mbpp \
  --prompt_type_mbpp "incoder" \
  --temperature 0.1 \
  --n_samples 15 \
  --batch_size 10 \
  --allow_code_execution=False 
	
# to evaluate on APPS
# to compute average/strict accuracies: use n_samples 1 
# to compute pass@k: use n_samples != 1 (200)
accelerate launch  main.py \
  --model <MODEL_NAME> \
  --max_length_generation <MAX_LENGTH> \
  --tasks apps \
  --level_apps <LEVEL> \
  --setup_apps <SETUP> \
  --n_samples 1 \
  --temperature 0.1 \
  --batch_size 1 \
  --allow_code_execution=False 

# to evaluate on another task such as code-to-text/conala/spider/concode with BLEU
accelerate launch  main.py \
  --model <MODEL_NAME> \
  --max_length_generation <MAX_LENGTH> \
  --tasks <TASK> \
  --n_samples 1 \
  --temperature 0.1 \
  --batch_size 1 
```

## Implementing new tasks
To implement a new task in this evaluation harness, see the guide in [`docs/guide`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/docs/guide.md). The are also contribution guidelines in this [`CONTRIBUTING.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/CONTRIBUTING.md)

## Documentation
We provide documentation for the existing benchmarks and how we make the evaluation in [`docs/README.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/main/docs/README.md).

## Remarks
* Currenltly, we use parallel evaluation across multiple GPUs using `accelerate`, this assumes that you can fit the model in one GPU. 
* Please note this evaluation harness tries to cover a wide set of models, but there could still be room for improvement based on each model, some might require different prompt engineering or post-processing of the code generations.
* For some scores of ongoing experiments please refer to [`example_scores/README.md`](https://github.com/bigcode-project/bigcode-evaluation-harness/blob/master/example_scores/README.md).

## Acknowledgements
This repository is inspired from [EleutherAI's LM evaluation harness](https://github.com/EleutherAI/lm-evaluation-harness).

## To do:
- [ ] test code-to-text for other languages than python
- [ ] test APPS one-shot setup


## Toolkit run
- sync `requriments.txt` and `Docekrfile` as the file is orginized to optimize frequent `docker build/push`
- set desired number of processes in `accelerate_cfg.yaml`
- set desired number of cores and memory in `Makefile` `run` target
- it is needed ot have data object `text2code_dataset_repo_workdir` in your tookit account
- run
  ```
  make run
  ```
