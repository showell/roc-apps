# ray

`fetch_exes.sh` pulls the canvas apps' Windows executables from the build box to
a Windows machine. Run it there, under WSL:

    scp steve@143.244.172.148:showell_repos/roc-apps/ray/fetch_exes.sh ~/
    chmod u+x ~/fetch_exes.sh && ~/fetch_exes.sh

The executables come from `.github/workflows/windows.yml`, run by hand:

    gh workflow run windows.yml
    gh run download <run-id> -n windows-exe -D ~/build/roc-apps/ray/windows

Building one natively on this box, or for Windows where the SDK is, is
`canvas_apps/native.sh`; see `canvas_apps/README.md`.
