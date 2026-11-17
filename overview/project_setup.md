# Baseline reproduction
## step 0: Create a conda environment
```bash
conda create -n artisan python=3.13 -y
conda activate artisan
pip install -U "huggingface_hub[cli]"
```

## step 1: Configure the environment
```bash
cd $(git rev-parse --show-toplevel)
./install.sh
```

## step 2: Download the dataset
set up Hugging Face token in the environment variable `HF_TOKEN`
```bash
cd $(git rev-parse --show-toplevel)
hf download mastercai/Artisan-Benchmark \
    --repo-type dataset \
    --local-dir ./benchmark/data
```


## step 3: Generate the baseline results
Firstly, make sure the directory of `cache_dir` and `blender` under `.artisan/config.toml` is consistent with the environmental setting
```bash
cd $(git rev-parse --show-toplevel)
tmux new -s artisan_experiment
```

### single cpu

```bash
# run all cases with default model gpt-6-astra as and thinking level high
.artisan/venv/bin/python benchmark/run.py --dataset ArtVIP --all --model <MODEL_NAME> --thinking <THINKING_LEVEL>

# ArtVIP
.artisan/venv/bin/python benchmark/run.py --dataset ArtVIP --all
# use gpt-6.1-sol 
.artisan/venv/bin/python benchmark/run.py \
    --dataset ArtVIP \
    --model gpt-6.1-sol \
    --thinking high \
    --all

# LightWheel
.artisan/venv/bin/python benchmark/run.py \
    --dataset LightWheel \
    --model claude-opus-5-5 \
    --provider anthropic \
    --thinking high \
    --all

# Stability
.artisan/venv/bin/python benchmark/run.py \
    --dataset Stability \
    --model claude-opus-5-5 \
    --provider anthropic \
    --thinking high \
    --all

# ABO-Mass
.artisan/venv/bin/python benchmark/run.py \
    --dataset ABO-Mass \
    --model claude-opus-5-5 \
    --provider anthropic \
    --thinking high \
    --all
```


### multiple cpu parallelization
```bash
cd $(git rev-parse --show-toplevel)

# ---- Settings ----
S=artisan_all                             # tmux session name
WORKERS=6                                 # number of parallel workers
CLAUDE="--provider anthropic --model claude-opus-5-5 --thinking high"
# One line per dataset, run in this order: "<dataset> <generation args>"
JOBS=(
  "ArtVIP     $CLAUDE"
  "Stability  $CLAUDE"
  "ABO-Mass   $CLAUDE"
  "LightWheel $CLAUDE"
)

# ---- Build the worker and progress commands (dry runs, no API calls) ----
RUN=""; PROGRESS=""
for job in "${JOBS[@]}"; do
  read -r d args <<< "$job"
  out=$(.artisan/venv/bin/python benchmark/run.py --dataset $d $args --all --dry-run \
        | python3 -c 'import json,sys; print(json.load(sys.stdin)["outputs"])')
  RUN+="ARTISAN_RENDER_DEVICE=cpu .artisan/venv/bin/python benchmark/run.py --dataset $d $args --all; "
  PROGRESS+="echo $d; bash benchmark/progress.sh $out benchmark/data/$d; "
done

# ---- Launch the workers, plus a progress window ----
# Each worker walks through the datasets in order. Workers share each dataset's queue through
# the per-case lock, and a worker moves on to the next dataset once no unclaimed case is left.
# Rendering stays on the CPU (render_device = "cpu" in .artisan/config.toml).
mkdir -p logs
tmux new-session -d -s $S -n progress
for i in $(seq $WORKERS); do
  tmux new-window -t $S -n w$i "{ $RUN } 2>&1 | tee -a logs/gen_${S}_w$i.log; exec bash"
  sleep 10   # stagger start-up so workers do not race for the same first case
done
tmux send-keys -t $S:progress "while :; do clear; $PROGRESS sleep 60; done" Enter
tmux attach -t $S

```



check the current progress
```bash
bash benchmark/progress.sh <OUTPUTS_DIR> <DATASET_DIR>
# by default, <OUTPUTS_DIR> is outputs/<DATASET>/<METHOD>, and <DATASET_DIR> is benchmark/data/<DATASET>
# example
bash benchmark/progress.sh outputs/ArtVIP/Artisan_GPT-6.1-Sol benchmark/data/ArtVIP
```

## step 4: Evaluate the results
```bash
cd $(git rev-parse --show-toplevel)
# evaluate on fidelity
.artisan/venv/bin/python benchmark/Evaluation/Fidelity/evaluate.py \
    --dataset ArtVIP \
    --method Artisan_GPT-6.1-Sol

# evaluate on collision
.artisan/venv/bin/python benchmark/Evaluation/Collision/evaluate.py \
    --dataset ArtVIP \
    --method Artisan_GPT-6.1-Sol

# evaluate on stability
.artisan/venv/bin/python benchmark/Evaluation/Stability/evaluate.py \
    --method Artisan_Claude-Opus-5-5


# evaluate on mass
.artisan/venv/bin/python benchmark/Evaluation/Mass/evaluate.py \ 
    --method Artisan_Claude-Opus-5-5

```
