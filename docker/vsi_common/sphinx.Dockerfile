FROM vsiri/recipe:gosu as gosu
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:pipenv as pipenv
FROM vsiri/recipe:vsi as vsi

FROM python:3.7.0

SHELL ["/usr/bin/env", "bash", "-euxvc"]

ENV WORKON_HOME=/venv \
    PIPENV_PIPFILE=/vsi/docker/vsi_common/sphinx.Pipfile \
    PIPENV_CACHE_DIR=/venv/cache \
    PYENV_SHELL=/bin/bash \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    JUSTFILE=/vsi/docker/vsi_common/sphinx.Justfile

COPY --from=pipenv /tmp/pipenv /tmp/pipenv
RUN /tmp/pipenv/get-pipenv; rm -rf /tmp/pipenv || :

# I need these Pipfiles before the rest of VSI below. This way the cache is only
# invalidated by the Pipfiles, not the rest of vsi_common
ADD sphinx.Pipfile sphinx.Pipfile.lock /vsi/docker/vsi_common/

RUN pipenv sync; \
    # Hack for vsi_domain
    ln -s /vsi/docs/vsi_domains.py "$(pipenv --venv)/lib/python3.7/site-packages/"; \
    rm -rf "${PIPENV_PIPFILE}*" /tmp/pip*

COPY --from=tini /usr/local /usr/local
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
# Allow non-privileged to run gosu (remove this to take root away from user)
RUN chmod u+s /usr/local/bin/gosu

COPY --from=vsi /vsi /vsi

ENTRYPOINT ["/usr/local/bin/tini", "--", "/usr/bin/env", "bash", "/vsi/linux/just_entrypoint.sh"]

CMD ["docs"]