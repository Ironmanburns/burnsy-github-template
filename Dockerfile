# Stub Dockerfile for apps created from burnsy-github-template.
# Replace the build stage with your language toolchain. Keep:
#   - multi-stage build
#   - non-root final image
#   - PORT=8080 / EXPOSE 8080
#   - binary or process that serves GET /healthz and GET /version
#
# Reference: sample-go Dockerfile (golang build → distroless/static:nonroot).

FROM gcr.io/distroless/static:nonroot
WORKDIR /
# COPY --from=build /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENV PORT=8080
# ENTRYPOINT ["/app"]
