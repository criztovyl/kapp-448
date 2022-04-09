FROM docker.io/bash
ENTRYPOINT ["bash", "-exc", "trap \"sleep ${TERM_SLEEP:-1}\" TERM; while sleep inf & wait; do echo infinity has passed; done"]
