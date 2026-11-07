import re
import csv
from pathlib import Path

# ==========================================================
# 1. DIRECTORY CONFIGURATION
# ==========================================================

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent

RUN_DIR = PROJECT_DIR / "runs" / "uart_run_1"

LOG_DIR = RUN_DIR / "logs"
REPORT_DIR = RUN_DIR / "reports"

OUTPUT_DIR = REPORT_DIR / "python_analysis"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

PHYSICAL_OUTPUT_FILE = OUTPUT_DIR / "physical_design_summary.csv"
TIMING_OUTPUT_FILE = OUTPUT_DIR / "timing_summary.csv"

STAGES = [
    "synthesis",
    "floorplan",
    "placement",
    "cts",
    "route"
]

# ==========================================================
# 2. AREA AND UTILIZATION EXTRACTION PATTERNS
# ==========================================================

AREA_PATTERNS = {

    "Chip Area": [
        r"Chip area for top module\s+.*?:\s*([\d.eE+-]+)"
    ],

    "Core Area": [
        r"Core area\s*:?\s*([\d.eE+-]+)"
    ],

    "Total Instances Area": [
        r"Total Instances Area\s*:?\s*([\d.eE+-]+)"
    ],

    "Placed Cell Area": [
        r"Placed Cell Area\s+([\d.eE+-]+)"
    ],

    "Available Free Area": [
        r"Available Free Area\s+([\d.eE+-]+)"
    ],

    "Final Placement Area": [
        r"final\s+placement\s+area\s*[:=]\s*([\d.eE+-]+)"
    ],

    "Die Area": [
        r"Die area\s*:\s*\(\s*([\d.eE+-]+)\s+([\d.eE+-]+)\s*\)"
        r"\s*\(\s*([\d.eE+-]+)\s+([\d.eE+-]+)\s*\)"
    ],

    "Design Area": [
        r"Design area\s+([\d.eE+-]+)\s*(?:um|µm)(?:\^?2|²)?"
    ],

    "Utilization": [
        r"Design area\s+[\d.eE+-]+\s*(?:um|µm)(?:\^?2|²)?"
        r"\s+([\d.eE+-]+)\s*%\s*utilization"
    ]
}


# ==========================================================
# 3. TIMING METRIC EXTRACTION PATTERNS
# ==========================================================

TIMING_PATTERNS = {

    "Data Required Time":
        r"^\s*(-?[\d.eE+-]+)\s+data\s+required\s+time\s*$",

    "Data Arrival Time":
        r"^\s*(-?[\d.eE+-]+)\s+data\s+arrival\s+time\s*$",

    "Slack (MET)":
        r"^\s*(-?[\d.eE+-]+)\s+slack\s*\(\s*met\s*\)\s*$"
}


# ==========================================================
# 4. WNS / WHS / TNS LOG MARKERS
# ==========================================================

TIMING_LOG_MARKERS = {

    "Setup WNS": "PD_SETUP_WNS",

    "Setup TNS": "PD_SETUP_TNS",

    "Hold WHS": "PD_HOLD_WHS",

    "Hold TNS": "PD_HOLD_TNS"
}


# ==========================================================
# 5. OUTPUT CSV HEADERS
# ==========================================================

PHYSICAL_FIELDNAMES = [
    "Stage",
    "Chip Area (µm²)",
    "Core Area (µm²)",
    "Total Instances Area (µm²)",
    "Placed Cell Area (µm²)",
    "Available Free Area (µm²)",
    "Final Placement Area (µm²)",
    "Die Area (µm²)",
    "Design Area (µm²)",
    "Utilization (%)"
]


TIMING_FIELDNAMES = [
    "Stage",

    "Setup Data Required Time (ns)",
    "Setup Data Arrival Time (ns)",
    "Setup Slack (ns)",
    "Setup WNS (ns)",
    "Setup TNS (ns)",

    "Hold Data Required Time (ns)",
    "Hold Data Arrival Time (ns)",
    "Hold Slack (ns)",
    "Hold WHS (ns)",
    "Hold TNS (ns)"
]


# ==========================================================
# 6. READ FILE CONTENT
# ==========================================================

def read_file(file_path):

    try:
        return file_path.read_text(
            encoding="utf-8",
            errors="ignore"
        )

    except OSError as error:
        print(f"[ERROR] Cannot read {file_path}: {error}")
        return ""


# ==========================================================
# 7. EXTRACT AREA AND UTILIZATION METRICS
# ==========================================================


DBU_PER_MICRON = 1000

def extract_synthesis_chip_area():
    synth_stat_file = REPORT_DIR / "synthesis" / "synth_stat.txt"

    if not synth_stat_file.exists():
        print(f"[WARNING] Synthesis statistics file not found: {synth_stat_file}")
        return None

    with open(synth_stat_file, "r") as file:
        content = file.read()

    pattern = r"Chip area for top module\s+.*?:\s*([\d.eE+-]+)"
    matches = re.findall(pattern, content)

    if matches:
        chip_area = float(matches[-1])
        print(f"[INFO] Synthesis Chip Area: {chip_area} µm²")
        return chip_area

    print("[WARNING] Top module Chip Area not found in synth_stat.txt")
    return None

def extract_metrics(text, patterns):

    extracted = {}

    for metric_name, regex_list in patterns.items():

        extracted[metric_name] = None

        for pattern in regex_list:

            matches = re.findall(
                pattern,
                text,
                re.IGNORECASE | re.MULTILINE
            )

            if matches:

                match = matches[-1]

                if metric_name == "Die Area":

                    x1, y1, x2, y2 = map(float, match)

                    width = (x2 - x1) / DBU_PER_MICRON
                    height = (y2 - y1) / DBU_PER_MICRON

                    extracted[metric_name] = round(
                        width * height, 4
                    )

                else:
                    value = float(match)
                    extracted[metric_name] = (
                            int(value) if metric_name == "Utilization" and value.is_integer()
                            else value
                    )

                break

    return extracted


# ==========================================================
# 8. FIND STAGE LOG
# ==========================================================

def find_stage_log(stage):

    if not LOG_DIR.exists():
        return None

    candidates = [
        path for path in LOG_DIR.rglob("*.log")
        if stage.lower() in path.stem.lower()
    ]

    if not candidates:
        return None


    for path in candidates:

        if path.stem.lower() == stage.lower():
            return path

    return sorted(candidates)[-1]


# ==========================================================
# 9. EXTRACT AREA FROM OPENROAD LOG
# ==========================================================

def extract_stage_area(stage):

    log_file = find_stage_log(stage)
    if log_file is None:

        print(f"[WARNING] {stage}: Log file not found.")
        return {}, None

    print(f"[INFO] Area source: {log_file.name}")

    text = read_file(log_file)

    area_metrics = extract_metrics(
        text,
        AREA_PATTERNS
    )
    if stage == "synthesis":
        synthesis_chip_area = extract_synthesis_chip_area()
        if synthesis_chip_area is not None:
            area_metrics["Chip Area"] = synthesis_chip_area


    return area_metrics, log_file


# ==========================================================
# 10. FIND SETUP / HOLD TIMING REPORT
# ==========================================================

def find_timing_report(stage, timing_type):

    stage_dir = REPORT_DIR / stage

    if not stage_dir.exists():
        return None

    for report_file in sorted(stage_dir.rglob("*")):

        if not report_file.is_file():
            continue

        filename = report_file.name.lower()

        if (
            timing_type in filename
            and "timing" in filename
            and filename.endswith((".txt", ".rpt"))
        ):
            return report_file

    return None


# ==========================================================
# 11. EXTRACT DETAILED TIMING METRICS
# ==========================================================

def extract_timing(report_file):

    text = read_file(report_file)

    metrics = {}

    for metric_name, pattern in TIMING_PATTERNS.items():

        matches = re.findall(
            pattern,
            text,
            re.IGNORECASE | re.MULTILINE
        )

        if matches:


            metrics[metric_name] = float(matches[-1])

        else:

            metrics[metric_name] = None

    return metrics


# ==========================================================
# 12. PROCESS SETUP AND HOLD REPORTS
# ==========================================================

def process_timing(stage, timing_type):

    report_file = find_timing_report(stage, timing_type)

    if report_file is None:

        print(
            f"[WARNING] {stage}: "
            f"{timing_type.upper()} report not found"
        )

        return {}

    print(
        f"[INFO] {timing_type.upper()} report: "
        f"{report_file.name}"
    )

    return extract_timing(report_file)


# ==========================================================
# 13. EXTRACT WNS / WHS / TNS FROM STAGE LOG
# ==========================================================

def extract_log_timing_metric(text, marker):

    lines = text.splitlines()

    for index, line in enumerate(lines):

        if marker in line:

            for output_line in lines[index + 1:index + 11]:

                numbers = re.findall(
                    r"(?<![A-Za-z_])[-+]?(?:\d+\.\d*|\.\d+|\d+)"
                    r"(?:[eE][-+]?\d+)?",
                    output_line
                )

                if numbers:

                    return float(numbers[-1])

    return None


def extract_log_timing(stage, log_file):

    metrics = {
        "Setup WNS": None,
        "Setup TNS": None,
        "Hold WHS": None,
        "Hold TNS": None
    }

    if log_file is None:
        return metrics

    text = read_file(log_file)

    for metric_name, marker in TIMING_LOG_MARKERS.items():

        metrics[metric_name] = extract_log_timing_metric(
            text,
            marker
        )

    return metrics


# ==========================================================
# 14. PROCESS ALL PHYSICAL DESIGN STAGES
# ==========================================================

def process_stages():

    physical_results = []
    timing_results = []

    for stage in STAGES:

        print(f"\n[INFO] Processing {stage.upper()}")

        # ------------------------------------------
        # PHYSICAL DESIGN ROW
        # ------------------------------------------

        physical_row = {
            "Stage": stage.upper() if stage == "cts" else stage.capitalize()
        }

        area_metrics, log_file = extract_stage_area(stage)

        area_header_mapping = {

            "Chip Area": "Chip Area (µm²)",

            "Core Area": "Core Area (µm²)",

            "Total Instances Area":
                "Total Instances Area (µm²)",

            "Placed Cell Area":
                "Placed Cell Area (µm²)",

            "Available Free Area":
                "Available Free Area (µm²)",

            "Final Placement Area":
                "Final Placement Area (µm²)",

            "Die Area": "Die Area (µm²)",

            "Design Area": "Design Area (µm²)",

            "Utilization": "Utilization (%)"
        }

        for metric_name, csv_header in area_header_mapping.items():

            physical_row[csv_header] = area_metrics.get(
                metric_name
            )

        physical_results.append(physical_row)

        # ------------------------------------------
        # TIMING ROW
        # ------------------------------------------

        timing_row = {
            "Stage": stage.capitalize()
        }

        # ------------------------------------------
        # SETUP TIMING
        # ------------------------------------------

        setup = process_timing(stage, "setup")

        timing_row["Setup Data Required Time (ns)"] = (
            setup.get("Data Required Time")
        )

        timing_row["Setup Data Arrival Time (ns)"] = (
            setup.get("Data Arrival Time")
        )

        timing_row["Setup Slack (ns)"] = (
            setup.get("Slack (MET)")
        )

        # ------------------------------------------
        # HOLD TIMING
        # ------------------------------------------

        hold = process_timing(stage, "hold")

        timing_row["Hold Data Required Time (ns)"] = (
            hold.get("Data Required Time")
        )

        timing_row["Hold Data Arrival Time (ns)"] = (
            hold.get("Data Arrival Time")
        )

        timing_row["Hold Slack (ns)"] = (
            hold.get("Slack (MET)")
        )

        # ------------------------------------------
        # WNS / WHS / TNS
        # ------------------------------------------

        log_timing = extract_log_timing(stage, log_file)

        timing_row["Setup WNS (ns)"] = (
            log_timing.get("Setup WNS")
        )

        timing_row["Setup TNS (ns)"] = (
            log_timing.get("Setup TNS")
        )

        timing_row["Hold WHS (ns)"] = (
            log_timing.get("Hold WHS")
        )

        timing_row["Hold TNS (ns)"] = (
            log_timing.get("Hold TNS")
        )

        timing_results.append(timing_row)

    return physical_results, timing_results


# ==========================================================
# 15. GENERATE PHYSICAL DESIGN CSV
# ==========================================================

def generate_physical_csv(results):

    with open(
        PHYSICAL_OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8"
    ) as csv_file:

        writer = csv.DictWriter(
            csv_file,
            fieldnames=PHYSICAL_FIELDNAMES
        )

        writer.writeheader()
        writer.writerows(results)

    print("\n[SUCCESS] Physical Design Summary Generated")
    print(f"[INFO] Output: {PHYSICAL_OUTPUT_FILE}")


# ==========================================================
# 16. GENERATE TIMING SUMMARY CSV
# ==========================================================

def generate_timing_csv(results):

    with open(
        TIMING_OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8"
    ) as csv_file:

        writer = csv.DictWriter(
            csv_file,
            fieldnames=TIMING_FIELDNAMES
        )

        writer.writeheader()
        writer.writerows(results)

    print("\n[SUCCESS] Timing Summary Generated")
    print(f"[INFO] Output: {TIMING_OUTPUT_FILE}")


# ==========================================================
# 17. MAIN FUNCTION
# ==========================================================

def main():

    print("\nUART PHYSICAL DESIGN AUTOMATION REPORT")
    print("--------------------------------------")

    if not RUN_DIR.exists():

        print(f"[ERROR] Run directory not found: {RUN_DIR}")
        return

    physical_results, timing_results = process_stages()

    generate_physical_csv(physical_results)

    generate_timing_csv(timing_results)

    print("\n================================================")
    print("[SUCCESS] UART PHYSICAL DESIGN AUTOMATION COMPLETED")
    print(f"[INFO] Stages processed: 7")
    print("================================================")


if __name__ == "__main__":
    main()
