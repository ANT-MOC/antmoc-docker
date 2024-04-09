# See https://github.com/slimtoolkit/slim

IMAGE=${1:-"antmoc/antmoc:dev-alpha"}
NEWTAG=${IMAGE%-*}

slim build \
  --mount $(pwd)/ant-moc:/opt/mnt/ant-moc \
  --http-probe=false \
  --show-clogs \
  --include-path /opt/software \
  --include-shell \
  --include-exe antmoc \
  --target $IMAGE \
  --tag $NEWTAG \
  --exec antmoc