#!/bin/bash
#SBATCH --nodes=1
#SBATCH --time=24:00:00
#SBATCH --job-name=npm_db
#SBATCH --partition=short
#SBATCH --mem=10G
#SBATCH -N 1
#SBATCH -n 1
#SBATCH --output=log.output
#SBATCH --error=log.error

rm npm_db.sqlite3 npm_db.sqlite3-journal ; RUST_BACKTRACE=full cargo run --release

echo "DONE (or failed)"
