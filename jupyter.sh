#!/bin/bash
#PBS -N PKN_GPU 
#PBS -l select=1:ncpus=16:ngpus=2:mem=64gb 
#PBS -l walltime=48:00:00
#PBS -q max_dgx
#PBS -j oe 
#PBS -o jupyter.log

source ~/.bashrc
# Activate your Python environment

micromamba activate MTBER

# Navigate to the working directory
cd $PBS_O_WORKDIR

# Run a Python script to test GPU access
python -c "
import torch
print('PyTorch Version:', torch.__version__)
print('CUDA Available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('CUDA Device Count:', torch.cuda.device_count())
    print('Current CUDA Device:', torch.cuda.current_device())
    print('CUDA Device Name:', torch.cuda.get_device_name(torch.cuda.current_device()))
"

python run.py
# Start JupyterLab on a specific port
jupyter lab --no-browser --ip=0.0.0.0 --port=8890 &> jupyter_output.log
