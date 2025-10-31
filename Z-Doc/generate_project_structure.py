import os

# --- Define the project structure ---
project_structure = {
    "project_root": {
        "README.md": "# Fil Rouge – Scoring & Fraud Detection Platform\n",
        "requirements.txt": "fastapi\npandas\nnumpy\npyspark\nmlflow\ngrafana-api\n",
        "config.yaml": "# Configuration globale du projet\n",
        "setup.sh": "#!/bin/bash\npip install -r requirements.txt\n",
        "docs": {
            "technical_guide": {
                "architecture_diagram.png": "",
                "api_documentation_swagger.yaml": "",
                "database_schema.png": "",
                "pipeline_workflow.png": "",
                "deployment_guide.md": "# Deployment Guide\n\nInstructions for Docker & Kubernetes setup.\n",
                "monitoring_setup.md": "# Monitoring Setup\n\nPrometheus & Grafana configuration.\n",
            },
            "user_guide": {
                "dashboard_manual.md": "# Dashboard Manual\n\nGuide for using the dashboard.\n",
                "api_usage_examples.md": "# API Usage Examples\n\nHow to call endpoints and interpret results.\n",
                "troubleshooting.md": "# Troubleshooting\n\nCommon issues and fixes.\n",
                "faq.md": "# FAQ\n\nFrequently asked questions.\n",
            },
            "project_management": {
                "jira_dashboard_screenshots": {
                    "velocity_chart.png": "",
                    "cycle_time_chart.png": "",
                    "burndown_chart.png": "",
                },
                "retrospective_reports": {
                    "retro_sprint1.md": "# Retrospective Sprint 1\n",
                    "retro_sprint2.md": "# Retrospective Sprint 2\n",
                    "retro_sprint3.md": "# Retrospective Sprint 3\n",
                },
                "weekly_meeting_notes": {
                    "week1_meeting.md": "# Week 1 Meeting Notes\n",
                    "week2_meeting.md": "# Week 2 Meeting Notes\n",
                    "week3_meeting.md": "# Week 3 Meeting Notes\n",
                },
                "kpi_tracking.xlsx": "",
            },
            "test_management": {
                "test_plan.md": "# Test Plan\n\nObjectives, tools, and methods.\n",
                "test_cases.xlsx": "",
                "xray_reports": {
                    "api_tests_report.pdf": "",
                    "pipeline_tests_report.pdf": "",
                    "ui_tests_report.pdf": "",
                },
                "bug_tracking_log.csv": "id,description,status,priority\n",
            },
            "presentation": {
                "fil_rouge_presentation.pptx": "",
                "script_presentation_en.md": "# Presentation Script (English)\n",
                "summary_onepage.pdf": "",
            },
        },
        "scripts": {
            "export_kpis.py": "# Script to export KPIs from Jira\n",
            "generate_reports.py": "# Script to generate weekly reports\n",
            "update_readme.sh": "#!/bin/bash\necho 'Updating README...'\n",
        },
        ".github": {
            "workflows": {
                "ci_cd.yml": "# CI/CD workflow for build and deploy\n",
            },
            "ISSUE_TEMPLATE.md": "# Issue Template\n",
            "PULL_REQUEST_TEMPLATE.md": "# Pull Request Template\n",
        },
    }
}


# --- Function to create directories and files ---
def create_structure(base_path, structure):
    for name, content in structure.items():
        path = os.path.join(base_path, name)
        if isinstance(content, dict):
            os.makedirs(path, exist_ok=True)
            create_structure(path, content)
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(content)


# --- Run creation ---
base_dir = os.getcwd()
create_structure(base_dir, project_structure)

print("✅ Project structure successfully created!")
