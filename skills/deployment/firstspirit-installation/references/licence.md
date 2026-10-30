# Licence information (on-premises)

Source: Installation Instructions (Provisioning, Installing the license file), BasicWorkflows documentation, `[odfs]`, read 2026-10-09.
Cloud: licences are managed by the platform service; this page is for on-prem.

## Getting and installing the file

- The licence file `fs-license.conf` is requested from Technical Support.
- Install either in ServerMonitoring (FirstSpirit, Configuration, License: paste the whole content unchanged, Save) or by putting the file in the server's `conf` directory.
- Changes to the file are picked up while the server runs, after a set interval; no restart.
- Without a licence: 30 minutes of use after each start, a warning to all logged-in users, then shutdown.
- Do not edit the file: a manipulated licence is invalid and the server no longer starts. A change such as a new IP address goes through Technical Support.
- Details of the file's parameters: Documentation for Administrators, Licence configuration (fs-license.conf).

## Flags that modules check

A module that needs a flag says so. BasicWorkflows needs `license.WORKFLOW` = 1 to create and run workflows. The other flags are listed per module in
`firstspirit-technical-product-knowledge` (`firstspirit-technical-product-knowledge/references/editions-and-licensing.md`) and in each module's own documentation.

File name: `fs-license.conf`, as in the Installation Instructions (2026.11) `[odfs]`; the BasicWorkflows documentation writes `fs_license.conf` for the same file.

## Not covered here

How to read the active flags in the clients, what each module does when its flag is missing, and licence behaviour in a cluster group: Documentation for Administrators and the module's own documentation.
