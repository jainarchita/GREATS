#!/bin/bash
# ============================================================
# Helper script for submitting GREATS jobs on PACE
# ============================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: ./submit_greats.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  submit [method]     Submit a GREATS job (default method: GREATS)"
    echo "                      Methods: Regular, GREATS, GradNorm, MaxLoss, RHO-Loss, SBERT"
    echo "  status              Check status of your jobs"
    echo "  cancel              Cancel all your pending/running jobs"
    echo "  logs [job_id]       View logs for a specific job (or latest if no ID)"
    echo "  account             Check your PACE allocation"
    echo "  setup               Set up the conda environment"
    echo ""
    echo "Examples:"
    echo "  ./submit_greats.sh submit              # Submit with GREATS method"
    echo "  ./submit_greats.sh submit Regular      # Submit with Regular (baseline) method"
    echo "  ./submit_greats.sh submit GradNorm     # Submit with GradNorm method"
    echo "  ./submit_greats.sh status              # Check job status"
    echo "  ./submit_greats.sh logs 12345          # View logs for job 12345"
}

submit_job() {
    METHOD=${1:-"GREATS"}

    # Validate method
    valid_methods=("Regular" "GREATS" "GradNorm" "MaxLoss" "RHO-Loss" "SBERT")
    if [[ ! " ${valid_methods[@]} " =~ " ${METHOD} " ]]; then
        echo -e "${RED}Invalid method: $METHOD${NC}"
        echo "Valid methods: ${valid_methods[*]}"
        exit 1
    fi

    # Create logs directory
    mkdir -p logs

    # Update the method in the SLURM script temporarily
    SLURM_SCRIPT="run_greats_pace.slurm"

    if [ ! -f "$SLURM_SCRIPT" ]; then
        echo -e "${RED}Error: $SLURM_SCRIPT not found${NC}"
        exit 1
    fi

    # Create a temporary script with the specified method
    TMP_SCRIPT="run_greats_${METHOD}_tmp.slurm"
    sed "s/^METHOD=\".*\"/METHOD=\"$METHOD\"/" "$SLURM_SCRIPT" > "$TMP_SCRIPT"

    echo -e "${GREEN}Submitting GREATS job with method: $METHOD${NC}"
    sbatch "$TMP_SCRIPT"

    # Clean up temporary script
    rm -f "$TMP_SCRIPT"

    echo ""
    echo "Use './submit_greats.sh status' to check job status"
}

check_status() {
    echo -e "${GREEN}Your jobs on PACE:${NC}"
    squeue -u $USER -o "%.10i %.15j %.8T %.10M %.6D %R"
}

cancel_jobs() {
    echo -e "${YELLOW}Cancelling all your jobs...${NC}"
    scancel -u $USER
    echo -e "${GREEN}Done!${NC}"
}

view_logs() {
    JOB_ID=$1

    if [ -z "$JOB_ID" ]; then
        # Find the latest log file
        LATEST_LOG=$(ls -t logs/greats_*.out 2>/dev/null | head -1)
        if [ -z "$LATEST_LOG" ]; then
            echo -e "${RED}No log files found in logs/ directory${NC}"
            exit 1
        fi
        echo -e "${GREEN}Viewing latest log: $LATEST_LOG${NC}"
        echo "----------------------------------------"
        tail -100 "$LATEST_LOG"
    else
        LOG_FILE="logs/greats_${JOB_ID}.out"
        ERR_FILE="logs/greats_${JOB_ID}.err"

        if [ -f "$LOG_FILE" ]; then
            echo -e "${GREEN}=== STDOUT ($LOG_FILE) ===${NC}"
            tail -100 "$LOG_FILE"
        fi

        if [ -f "$ERR_FILE" ] && [ -s "$ERR_FILE" ]; then
            echo ""
            echo -e "${RED}=== STDERR ($ERR_FILE) ===${NC}"
            tail -50 "$ERR_FILE"
        fi
    fi
}

check_account() {
    echo -e "${GREEN}Your PACE allocation:${NC}"
    pace-quota 2>/dev/null || echo "pace-quota command not available. Try: pace-check-resources"
}

setup_env() {
    echo -e "${GREEN}Setting up GREATS conda environment...${NC}"
    echo ""

    module purge
    module load anaconda3
    module load cuda/11.8

    # Check if environment exists
    if conda env list | grep -q "greats"; then
        echo "Environment 'greats' already exists."
        read -p "Do you want to update it? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            conda activate greats
            pip install -r requirement.txt
        fi
    else
        echo "Creating new 'greats' environment..."
        conda create -n greats python=3.10 -y
        conda activate greats
        pip install -r requirement.txt
    fi

    echo ""
    echo -e "${GREEN}Setup complete!${NC}"
    echo "Activate with: conda activate greats"
}

# Main command handler
case "$1" in
    submit)
        submit_job "$2"
        ;;
    status)
        check_status
        ;;
    cancel)
        cancel_jobs
        ;;
    logs)
        view_logs "$2"
        ;;
    account)
        check_account
        ;;
    setup)
        setup_env
        ;;
    *)
        usage
        ;;
esac
