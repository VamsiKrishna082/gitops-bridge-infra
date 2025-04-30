htpasswd -nbBC 10 "" "your_new_password" | tr -d ':\n' | sed 's/^$2y/$2a/'


kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {
    "admin.password": "$2a$10$IauetkRqe209DCET/ZdlrOyVgJ4AIMFL/QD2tGDOEs60jTr06qE96",
    "admin.passwordMtime": "'$(date +%FT%T%Z)'"
  }}'
