#!/bin/bash
#SBATCH --job-name=greats_llm
#SBATCH --output=logs/greats_%j.out
#SBATCH --error=logs/greats_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=192GB
#SBATCH --gres=gpu:A100:1
#SBATCH --time=12:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=YOUR_EMAIL@gatech.edu

# ============================================================
# GREATS: Online Batch Selection for LLM Fine-tuning
# Georgia Tech PACE Cluster
# ============================================================

# Print job information
echo "=============================================="
echo "GREATS Job Started"
echo "=============================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "Start Time: $(date)"
echo ""

# Create logs directory if it doesn't exist
mkdir -p logs

# Load required modules
module purge
module load anaconda3
module load cuda/11.8

# Activate conda environment (create one if needed: conda create -n greats python=3.10)
conda activate greats

# Print environment information
echo "Environment Information:"
echo "------------------------"
nvidia-smi
echo ""
python --version
python -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"N/A\"}')"
echo ""

# Navigate to project directory
cd $SLURM_SUBMIT_DIR
echo "Working Directory: $(pwd)"
echo ""

# ============================================================
# CONFIGURATION - Modify these parameters as needed
# ============================================================

# Selection method: Regular, GREATS, GradNorm, MaxLoss, RHO-Loss, SBERT
METHOD="GREATS"

# Training parameters
BATCH_SIZE=2                    # Batch size (2-4 typical for LLMs)
PERCENTAGE=0.05                 # Data percentage (0.05 = 5% of dataset)
NVAL=5                          # Validation size
TASK="mmlu"                     # Task name
MODEL="llama2"                  # Model (llama2 = meta-llama/Llama-2-7b-hf)
LORA_ALPHA=1                    # LoRA alpha parameter
LEARNING_RATE=2e-05             # Learning rate
SEED=42                         # Random seed
GRADIENT_ACCUMULATION=1         # Gradient accumulation steps
SUBJECT="sociology"             # MMLU subject (e.g., sociology, world_religions, etc.)

# ============================================================
# Run GREATS
# ============================================================

echo "=============================================="
echo "Running GREATS with configuration:"
echo "  Method: $METHOD"
echo "  Batch Size: $BATCH_SIZE"
echo "  Data Percentage: $PERCENTAGE"
echo "  Task: $TASK"
echo "  Subject: $SUBJECT"
echo "  Learning Rate: $LEARNING_RATE"
echo "  Seed: $SEED"
echo "=============================================="
echo ""

# Run the training script
./online_batch_select_mmlu.sh \
    "$METHOD" \
    "$BATCH_SIZE" \
    "$PERCENTAGE" \
    "$NVAL" \
    "$TASK" \
    "$MODEL" \
    "$LORA_ALPHA" \
    "$LEARNING_RATE" \
    "$SEED" \
    "$GRADIENT_ACCUMULATION" \
    "$SUBJECT"

# Capture exit status
EXIT_STATUS=$?

# Print completion information
echo ""
echo "=============================================="
echo "Job Completed"
echo "=============================================="
echo "End Time: $(date)"
echo "Exit Status: $EXIT_STATUS"

if [ $EXIT_STATUS -eq 0 ]; then
    echo "Job completed successfully!"
else
    echo "Job failed with exit status $EXIT_STATUS"
fi

exit $EXIT_STATUS
