# Contributing to OstrichDB

First off, thank you for considering contributing to OstrichDB!

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report for OstrichDB. Following these guidelines helps understand your report, reproduce the behavior, and find related reports.

- Use a clear and descriptive title for the issue to identify the problem.
- Describe the exact steps which reproduce the problem in as many details as possible.
- Provide specific examples to demonstrate the steps.
- Describe the behavior you observed after following the steps and point out what exactly is the problem with that behavior.
- Explain which behavior you expected to see instead and why.
- Include screenshots and animated GIFs which show you following the described steps and clearly demonstrate the problem.

### Suggesting Enhancements/Features

This section guides you through submitting an enhancement suggestion for OstrichDB, including completely new features and minor improvements to existing functionality.

- Use a clear and descriptive title for the issue to identify the suggestion.
- Provide a step-by-step description of the suggested enhancement in as many details as possible.
- Provide specific examples to demonstrate the steps or point out the part of OstrichDB where the suggestion is related to.
- Describe the current behavior and explain which behavior you expected to see instead and why.
- Explain why this enhancement would be useful to most OstrichDB users.

### Pull Requests

1. **Branch Naming Convention:**
   - Use no more than five words, separated by hyphens.
   - If there's an associated issue, add the issue number at the end of the branch name.
   - Example: `add-user-authentication-feature-123`

2. **Code Style:**
   - Keep your code as close to the current style in the project as possible.
   - Consistency with existing code is prioritized over strict adherence to external style guides.

3. **Pull Request Size:**
   - Keep PRs relatively small and focused.
   - Avoid submitting PRs with thousands of lines of changes.
   - If a feature requires extensive changes, consider breaking it into smaller, logically separated PRs.

4. **Commits:**
   - Keep commits focused on a single change.
   - Use clear and descriptive commit messages.

5. **Code Review:**
   - Be open to feedback. Just because you submit a PR, it doesn't mean it will be merged as is.
   - Make requested changes promptly.

### Issue and Pull Request Labels

This section lists the labels we use to help us track and manage issues and pull requests.

* `Bug:` - Issues that are bugs in the DBMS
* `Feature:` - Issues that are DBMS feature requests
* `Documentation:` - Issues that are related to DBMS documentation
* `Brainstorms:` - Issues that are for brainstorming DBMS features and improvements

## Getting Started

For something that is bigger than a one or two line fix:

1. Create your own fork of the codebase
2. Do the changes in your fork
3. If you like the change and think the project could use it:
   * Be sure you have followed the code style for the project.
   * Submit a pull request to the main repository.
*IMPORTANT*: Submit the PR to the `development ` NOT `main`.

As a rule of thumb, changes are obvious fixes if they do not introduce any new functionality or creative thinking. As long as the change does not affect functionality, some likely examples include the following:

* Spelling / grammar fixes
* Typo correction, white space and formatting changes
* Comment clean up
* Bug fixes that change default return values or error codes stored in constants
* Adding logging messages or debugging output
* Changes to 'metadata' files like .gitignore, build scripts, etc.
* Moving source files from one directory or package to another

## Developing OstrichDB

To set up your environment to develop OstrichDB, follow the installation instructions in the README.
