# Security Policy

cherry is an open source, charity-first resale platform handling real users, charities and sensitive data. We therefore take security very seriously and strongly encourage responsible and full disclosure of any vulnerabilities.

## Supported versions

At this stage of the project we only provide security updates for the actively developed code on GitHub.

| Version / branch         | Supported for security fixes |
| ------------------------ | --------------------------- |
| `main`                   | ✅ Yes                      |
| Latest tagged release    | ✅ Yes                      |
| Any older tag or branch  | ❌ No                       |

If you are using a fork or a long-lived feature branch and discover a security issue, please still report it. We will assess and, where appropriate, fix the issue on `main` and the latest tagged release.

## Scope

This security policy applies to:

- The public cherry GitHub repositories and their source code  
- The cherry mobile applications built from these repositories  
- Any backend services and APIs that are part of the official cherry stack

Out of scope:

- Third party providers such as Stripe, Firebase, courier APIs, analytics tools and other vendors  
- Any forks of the project that are not operated by the cherry maintainers  
- Social engineering, physical attacks or spam campaigns

If you are unsure whether something is in scope, report it privately and we will confirm.

## How to report a vulnerability

Please use **private, coordinated disclosure**. Do not create a public GitHub issue for suspected vulnerabilities.

You can report a vulnerability in either of these ways:

1. **GitHub private security advisory** (preferred)  
   - Go to the repository on GitHub  
   - Click **Security** → **Report a vulnerability**  
   - Fill in the advisory form with as much detail as possible  [oai_citation:0‡GitHub Docs](https://docs.github.com/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)  

2. **Email**  
   - Send a detailed report to: `bradleyvenn@cherry.org.uk`  
   - Use the subject line: `SECURITY: <short description>`  
   - If you need to share particularly sensitive details, please ask for a secure channel in your first message.

If neither option is possible for you, contact a maintainer directly and we will help arrange a secure reporting route.

### What to include in your report

To help us triage and fix the issue efficiently, please include:

- A clear, concise description of the vulnerability  
- The affected component or file (repository, path, commit hash or app version)  
- Exact steps to reproduce the issue  
- Expected behaviour and actual behaviour  
- Any proof of concept code, payloads or minimal test cases  
- Impact assessment (for example: information disclosure, privilege escalation, remote code execution)  
- Any relevant logs or screenshots, with sensitive data removed or anonymised

Please avoid including real user data in examples. Synthetic or anonymised data is preferred.

## Disclosure and response process

cherry is a volunteer-led, non-profit project. We cannot currently guarantee strict service-level agreements but we commit to the following targets:

- **Initial acknowledgement**: within 5 business days of receiving your report  
- **Initial triage** (confirm severity and scope): within 10 business days  
- **Fix development and testing**: prioritised by severity and impact  
- **Coordinated disclosure**: we will agree with you when and how details can be made public

Severity guidelines:

- **Critical / High** (for example: remote code execution, unauthorised access to user or charity data, bypass of payment or escrow logic): treated as highest priority and worked on as soon as possible  
- **Medium** (for example: privilege issues, significant input validation problems, logic flaws that need user interaction): scheduled promptly  
- **Low / Informational** (for example: minor header misconfigurations, rate-limiting gaps without obvious exploitation path): addressed as part of regular maintenance

When a fix is ready we will:

- Patch the `main` branch and the latest supported release  
- Prepare release notes that mention a security fix, with enough information for users to understand the impact, but without enabling easy exploitation  
- Credit you (if you wish) in the changelog or security notes

If we decide that a reported issue is not a security vulnerability, we will explain why and, where appropriate, track it as a regular bug or feature request.

We follow the principle of **coordinated vulnerability disclosure**, making details public only after a mitigation or fix is available wherever reasonably possible.  [oai_citation:1‡Red Hat Developer](https://developers.redhat.com/articles/2024/02/06/security-policies-open-source-software)  

## Safe harbour for good faith research

We welcome responsible security research that helps keep our users and charities safe. As long as you act in **good faith**, we commit not to pursue legal action or report you to authorities for your research on cherry systems covered by this policy.  [oai_citation:2‡Bugcrowd Docs](https://docs.bugcrowd.com/researchers/disclosure/disclose-io-and-safe-harbor)  

Good faith means that you:

- Only test systems that are clearly in scope  
- Avoid any action that could harm users, charities or the platform’s availability  
- Do not exploit a vulnerability beyond what is necessary to prove it exists  
- Do not access, modify, store or exfiltrate personal data, financial data or confidential information  
- Do not attempt social engineering, phishing, spamming or physical attacks  
- Respect rate limits and do not perform excessive automated scanning that could degrade service  
- Keep technical details confidential until we have had a reasonable chance to investigate and fix the issue  
- Comply with relevant laws in your jurisdiction

If in doubt, ask us before proceeding with testing.

This safe harbour does not apply to any activity that is clearly malicious, destructive or performed in bad faith.

## What is out of scope for reporting

To keep our limited volunteer time focused on the most important risks, the following are generally not treated as security vulnerabilities:

- Missing security headers that have low practical impact  
- Lack of support for very old, insecure browsers  
- Known issues in third party libraries where no practical exploit exists in our context  
- Bugs that require a compromised user device, rooted phone or malware on the user’s system  
- Issues that only affect unsupported branches or unmodified forks  
- Self-XSS that requires the victim to paste code into their own browser console

If you are unsure whether an issue is worth reporting, you can still contact us privately and we will clarify. It is better to ask than to stay silent.

## Non-security issues

For non-security bugs, feature requests, documentation improvements and general discussion, please continue to use:

- **GitHub Issues** for bug reports and feature requests  
- **Pull requests** for code and documentation contributions

This keeps security reports private and allows us to handle them with the care they require.  [oai_citation:3‡Open Source Guides](https://opensource.guide/security-best-practices-for-your-project)  

## No bug bounty (for now)

We do not currently run a paid bug bounty programme. We may, with your permission, acknowledge significant contributions publicly in our release notes or documentation.

---

Thank you for helping to keep cherry and its users secure! 🍒
