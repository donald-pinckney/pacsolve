#!/usr/bin/env python3
import os
import sys
from pathlib import Path
import pandas as pd
import re
import numpy as np
from tqdm import tqdm
from lockfile_metrics import SolveResultEvaluation
from tqdm.contrib.concurrent import process_map
import csv


def main():
    if len(sys.argv) != 2:
        print("Usage: python3 preprocess_vuln_exp.py [exp dir, e.g. /scratch/a.guha/exp/]")
        sys.exit(1)
    exp_dir_path = Path(sys.argv[1])

    dirs = list(exp_dir_path.iterdir())
    records = [r for rrs in map(process_child_dir, tqdm(dirs)) for r in rrs]

    df = pd.DataFrame.from_records(records, columns=["name", "commit", "solver", "CVE", "NDeps", "Status", "Time"], index=["name", "commit", "solver"])
    print(df.to_csv())


PACKAGE_DIR_RE = re.compile('package-(.*)-([^-].*)\\.(tgz|json)')
def process_child_dir(child):
    if not child.is_dir():
        return []
    raw_name = child.name
    m = PACKAGE_DIR_RE.match(raw_name)
    name = m.group(1)
    commit = m.group(2)
    package_dir = child / "package"
    rows = process_package_dir(package_dir, name, commit)
    return rows


def process_package_dir(p_dir, name, commit):
    vanilla_path = p_dir / "vanilla-lockfile.json"
    audit_fix_path = p_dir / "auditfix-lockfile.json"
    audit_force_path = p_dir / "auditfixforce-lockfile.json"
    maxnpm_cve_oldness_path = p_dir / "maxnpmcveoldness-lockfile.json"
    maxnpm_pip_else_npm_path = p_dir / "maxnpmcveoldness_pip-else-npm-lockfile.json"

    return [
        process_lockfile_csv(vanilla_path, name, commit, 'vanilla'),
        process_lockfile_csv(audit_fix_path, name, commit, 'audit fix'),
        process_lockfile_csv(audit_force_path, name, commit, 'audit fix force'),
        process_lockfile_csv(maxnpm_cve_oldness_path, name, commit, 'maxnpm_cve_oldness'),
        process_lockfile_csv(maxnpm_pip_else_npm_path, name, commit, 'maxnpm_cve_oldness_pip_else_npm')
    ]

def process_lockfile_csv(lockfile_path, name, commit, solver_name):
    csv_path = Path(str(lockfile_path) + ".csv")

    if not csv_path.exists():
        if lockfile_path.exists():
            print(f"WARNING: missing {csv_path} for {lockfile_path}", file=sys.stderr)
            pass
            
        record = {
            'NDeps': np.float64(np.nan),
            'CVE': np.float64(np.nan),
            'Time': np.float64(np.nan),
            'Status': 'missing'
        }
    else:
        with open(csv_path, newline='') as csvfile:
            csvreader = csv.DictReader(csvfile)
            rows = list(csvreader)
        
        if len(rows) != 1:
            print(f"FATAL: BROKEN CSV FILE: {csv_path}", file=sys.stderr)
            record = {
                'NDeps': 0,
                'CVE': 0,
                'Time': 0,
                'Status': 'BAD'
            }
        else:
            csvrow = rows[0]
            record = {
                'NDeps': np.float64(csvrow['NDeps']),
                'CVE': np.float64(csvrow['CVE']),
                'Time': np.float64(np.nan),
                'Status': csvrow['Status']
            }

    record['solver'] = solver_name
    record['name'] = name
    record['commit'] = commit
    return record






if __name__ == "__main__":
    main()
