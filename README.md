# 🖥️ Automated Asset Inventory & Classification (Ansible | NIST CSF ID.AM)
An Ansible-based automation project designed to discover, classify, and document enterprise assets in alignment with the NIST Cybersecurity Framework (CSF) — specifically the IDENTIFY (ID) function and Asset Management (ID.AM-1 through ID.AM-5) controls.

This project focuses on building repeatable, production-safe automation that improves asset visibility, strengthens governance, and lays the groundwork for risk management and incident readiness.

## ✨ Technologies
  - Ansible
  - YAML
  - Jinja2 templating
  - JSON / YAML / HTML reporting
  - Linux system utilities
  - NIST Cybersecurity Framework (CSF)

## 🚀 Features
  - Automated discovery of enterprise assets
  - Collection of system metadata (OS, hardware, versions)
  - Enumeration of:
    - Installed software
    - Running services
    - Open TCP ports
  - Network interface and IP configuration mapping
  - Asset classification by environment and criticality
  - Multi-format reporting for CMDB and compliance workflows:
    - JSON
    - YAML
    - HTML
  - Production-grade runner with:
    - Pre-flight environment checks
    - Variable validation
    - Fail-safe execution logic before every run

## 🧠 The Process

This project started with a simple question:
“How can asset inventory be made continuous, accurate, and audit-ready?”

Manual inventories quickly become outdated and unreliable, especially at scale. I used Ansible to automate live asset discovery and focused heavily on defensive automation — ensuring every run validates prerequisites before touching a system.

As the playbooks evolved, I layered in:
  - Advanced fact gathering
  - Jinja2 templating to transform raw data into structured reports
  - Control mapping to NIST CSF ID.AM requirements
The result is an automation pipeline that doesn’t just collect data, but turns system facts into governance-ready intelligence.

## 🧪 What I Learned
  - How to design Ansible playbooks for idempotence and safety
  - Translating cybersecurity frameworks into practical automation
  - Structuring raw system data into meaningful compliance artifacts
  - The value of pre-flight validation in production environments
  - Why asset visibility is foundational to detection, response, and risk reduction

This project reinforced how infrastructure automation and cybersecurity governance intersect, especially in regulated or enterprise environments.

## 🛡️ NIST CSF Alignment
This automation directly supports:
  - ID.AM-1 – Physical devices and systems inventoried
  - ID.AM-2 – Software platforms and applications inventoried
  - ID.AM-3 – Organizational communication and data flows identified
  - ID.AM-4 – External information systems cataloged
  - ID.AM-5 – Resources prioritized by classification and criticality

## 🤖 AI-Assisted Development
Throughout development, I leveraged ChatGPT (GPT-5) and Claude to:
  - Generate and refine YAML boilerplate
  - Debug complex variable and templating logic
  - Review playbooks for scalability and idempotence
  - Improve documentation clarity and structure
AI tools accelerated iteration while architectural decisions and validation remained manual.

## 📷 Preview
<img width="1920" height="1080" alt="S4" src="https://github.com/user-attachments/assets/eef53d11-0ff5-4c0c-856e-83ad1ac3d62c" />

