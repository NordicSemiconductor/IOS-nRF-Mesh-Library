name: Bug Report
description: Create a report to help us improve nRF Mesh.
labels: ["bug"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!
  - type: dropdown
    id: version
    attributes:
      label: Version
      description: What version of our software are you running?
      options:
        - 4.0.1 (Latest)
        - 4.0.0
        - 3.2.0
      default: 0
    validations:
      required: true
  - type: textarea
    id: what-happened
    attributes:
      label: Describe the issue
      description: Describe the issue, expected and actual result.
      placeholder: |
        1. Go to '...'
        2. Click on '...'
        3. Scroll down to '...'
        4. ...
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Relevant log output
      description: Please copy and paste any relevant log output. This will be automatically formatted into code, so no need for backticks.
      render: shell