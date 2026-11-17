# Overview
For reproduction/modification/exploration of any existing project with the open source code from either published or preprint paper. 

When you get a new github repo with open source code, you should consider adding the following to comprehend the project.

Here are a template of typical additional contents given an open source code repository for reproduction or further exploration.

# ASCII tree structure
📁 Project_Root/
├── 📁 overview/                    # as a folder recording the project overview, including architecture, methodology, dataset, and evaluation metric
│   ├── 📄 README.md                # sketch outline of the project idea as the abstract
│   ├── 📜 env_setup.sh             # one-time environment setup script
│   ├── 📄 dataset.md               # dataset conclusion and reference from paper
│   ├── 📜 data_prepare.sh          # one-time script to download the dataset and get it structured in a new server
│   ├── 📄 methodology.md           # core idea from the paper in methodology part
│   ├── 📄 model.md    # specify the basic terminology/notations/model architecture in the project, and trainable parameters
│   ├── 📄 loss.md                  # conclude the loss functions used in the model training
│   ├── 📄 eval_metric.md           # evaluation metric for model performance assessment
│   ├── 📄 notation.md              # mathematical notation instruction
│   ├── 📄 formulations.md          # mathematical computation and algorithm design
│   ├── 📄 project_architecture.md  # clearly summarize core folders of the repository with ASCII tree, especially the dataset and model training scripts with a tree based structure
│   └── 📄 project_setup.md         # explicitly illustrate detailed steps to reproduce the results
├── 📁 data/                        # dataset folder, typically with train/val/test split
├── 📁 model/                       # all scripts regarding model implementation
├── 📁 utils/                       # all scripts including various tools
├── 📁 output/                      # all experiment final results for presentation
├── 📁 debug/                       # contain files for debugging
├── 📁 experiment/                  # It concludes all intermediate experimental results for debugging
├── 📁 work_progress/               # It records the iterative work progress for the following plan, currently finished work and the expected outcome.
│   ├── 📄 code_change.md           # detailed modified code from the original repo version for smooth code execution 
│   ├── 📄 notes.md(optional)       # record notes and big direction from advisors/collaborators
│   ├── 📄 ongoing_task.md          # ongoing tasks to be finished as intermediate steps for phased work
│   ├── 📄 finished_task.md(optional) # record finished tasks globally for each part of the project
│   └── 📄 work_stage_x.md          # work progress for each stage including finished tasks, potential next steps, requests and questions
└── 📁 SLURM_execution/             # It stores all scripts and execution results from HPC clusters
    ├── 📁 SLURM_outcome/           # stores all execution results after the model, particularly the time logs        
    ├── 📁 SLURM_output/            # includes all execution output files during the model training/inference/evaluation, ending in `.err` and `.out`
    └── 📁 SLURM_script/            # contains all SLURM scripts for submission in HPC clusters, ending in `.sh`

# one-step setup
- download git_script
enter: git@github.com:Louis-26/research_materials
then: SLURM_execution work_progress overview
```bash
#!/bin/bash
# Description: Download one or more folders from a git repository (sparse checkout).
# Usage:  bash download_folders.sh
# Default save location = root of the git repo you run this script from
# (git rev-parse --show-toplevel); falls back to the current directory.
# ~/TMP_DOWNLOADS is only a temporary workspace: it is created for the download
# and removed automatically after the folders are moved out.
# https urls are auto-converted to ssh (git@host:user/repo) so that your ssh key
# is used instead of typing a token every time. Set USE_SSH=false to disable.

main() {
    local REPO_URL BRANCH_NAME SAVE_DIR WORK_DIR FOLDER_NAME DEST ANSWER
    local -a FOLDER_NAMES
    local DEFAULT_SAVE_DIR DEFAULT_REPO_URL=""
    local TMP_ROOT="$HOME/TMP_DOWNLOADS"
    local USE_SSH=true                   # false = keep https urls as-is

    # default save dir = toplevel of the repo you are currently in
    if DEFAULT_SAVE_DIR=$(git rev-parse --show-toplevel 2>/dev/null); then
        DEFAULT_REPO_URL=$(git config --get remote.origin.url)
    else
        DEFAULT_SAVE_DIR="$PWD"          # not inside a repo -> save to where you run it
    fi

    read -r -p "Enter the url of the target repo
(e.g., https://github.com/Louis-26/personal_note), press Enter to use current repo [$DEFAULT_REPO_URL]: " REPO_URL
    read -r -p "Enter the folder name(s) from git repo
(multiple folders separated by spaces, e.g., folder1 docs/folder2): " -a FOLDER_NAMES
    read -r -p "Enter the branch name (default is main): " BRANCH_NAME
    read -r -p "Enter the local directory to save into
(press Enter to use: $DEFAULT_SAVE_DIR): " SAVE_DIR

    # set variables
    BRANCH_NAME=${BRANCH_NAME:-main}
    REPO_URL=${REPO_URL:-$DEFAULT_REPO_URL}
    REPO_URL="${REPO_URL%/}"             # drop trailing slash
    REPO_URL="${REPO_URL%.git}"          # strip trailing .git to avoid "xxx.git.git"
    # https://github.com/user/repo  ->  git@github.com:user/repo   (ssh key auth, no token)
    if [ "$USE_SSH" = true ] && [[ "$REPO_URL" =~ ^https?://([^/@]+@)?([^/]+)/(.+)$ ]]; then
        REPO_URL="git@${BASH_REMATCH[2]}:${BASH_REMATCH[3]}"
        echo "Using SSH url: ${REPO_URL}.git"
    fi
    SAVE_DIR="${SAVE_DIR:-$DEFAULT_SAVE_DIR}"
    SAVE_DIR="${SAVE_DIR//\\//}"         # windows style path -> unix style

    if [ -z "$REPO_URL" ]; then
        echo "Error: no repo url entered and current directory is not a git repo." >&2
        return 1
    fi
    if [ ${#FOLDER_NAMES[@]} -eq 0 ]; then
        echo "Error: no folder name entered." >&2
        return 1
    fi

    if ! mkdir -p "$SAVE_DIR"; then
        echo "Error: cannot create save directory: $SAVE_DIR" >&2
        return 1
    fi
    SAVE_DIR=$(cd "$SAVE_DIR" && pwd)    # normalize to absolute path

    # temp workspace lives inside ~/TMP_DOWNLOADS
    mkdir -p "$TMP_ROOT" || return 1
    WORK_DIR=$(mktemp -d "$TMP_ROOT/git_dl.XXXXXX") || return 1
    cd "$WORK_DIR" || return 1

    git init -q
    git remote add origin "${REPO_URL}.git"
    git sparse-checkout init --no-cone
    git sparse-checkout set "${FOLDER_NAMES[@]}"    # all folders in one shot
    if ! git pull "$REPO_URL" "$BRANCH_NAME"; then
        echo "Error: git pull failed. Check repo url / branch name / network." >&2
        cd "$SAVE_DIR" && rm -rf "$WORK_DIR"
        rmdir "$TMP_ROOT" 2>/dev/null
        return 1
    fi

    # move each target folder to the save directory
    for FOLDER_NAME in "${FOLDER_NAMES[@]}"; do
        if [ ! -e "$FOLDER_NAME" ]; then
            echo "Warning: folder '$FOLDER_NAME' not found in repo (check spelling / branch)." >&2
            continue
        fi
        DEST="$SAVE_DIR/$(basename "$FOLDER_NAME")"
        if [ -e "$DEST" ]; then
            read -r -p "'$DEST' already exists. Overwrite? [y/N]: " ANSWER
            if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
                rm -rf "$DEST"
            else
                echo "Skipped: $FOLDER_NAME"
                continue
            fi
        fi
        mv "$FOLDER_NAME" "$SAVE_DIR/"
        echo "Downloaded: $DEST"
    done

    # cleanup: delete the workspace, then remove TMP_DOWNLOADS itself.
    # rmdir only deletes an EMPTY directory, so if you keep anything of your
    # own inside ~/TMP_DOWNLOADS it will never be touched.
    cd "$SAVE_DIR" && rm -rf "$WORK_DIR"
    rmdir "$TMP_ROOT" 2>/dev/null
    echo "Done! Folders saved under $SAVE_DIR"
}

main "$@"
```

- finish basic structure setup
```bash
cd $(git rev-parse --show-toplevel)/overview
rm -rf README.md
```

- update .gitignore
```bash
echo -e "git_script\n" >> .gitignore
echo -e "SLURM_execution\n" >> .gitignore
```

# Reference
ASCII tree generator reference: https://ascii-tree-generator.com/
