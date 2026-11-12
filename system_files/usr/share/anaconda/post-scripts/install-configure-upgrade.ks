%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ghcr.io/lyranile/manganite:latest
%end
