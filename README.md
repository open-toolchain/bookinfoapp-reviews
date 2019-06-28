# Bookinfo Reviews Application

Created from [the source of the Istio sample Bookinfo service reviews](https://github.com/istio/istio/tree/master/samples/bookinfo/src/reviews) with the following additions and changes:

- Added `Dockerfile` to compile and build image as follows:

        docker build -t namespace/repository:tag .

- Removed `reviews-wlpcfg/Dockerfile`. The top level `Dockerfile` replaces this.
- Added `kustomize` folder for deployment of the service as follows:

        kustomize build ./kustomize | kubectl apply -f -

- Added `iter8/experiment.yaml` as a sample iter8 `Experiment` resource.
- Modified `reviews-application/src/main/java/application/java/LibertyRestEndpoint.java`. The aim is produce a version in which changes trigger the automated build of a new image rather than the building of three fixed images from the same code.
    - Remove dependency on environment variables for ratings and star colors. Instead, these are hardcoded in the code and must be changed to create new versions of the application. 
    - Determine if ratings are enabled by the star color; the color `none` means ratings are not enabled
    - Introduce an optional 5s delay when the star color is yellow (allowing for a simple way to produce a slow version).

This modified code was used to produce 4 versions available from [dockerhub](https://cloud.docker.com/u/iter8/repository/docker/iter8/reviews):

- `iter8/reviews:istio-v1` - color set to `none`
- `iter8/reviews:istio-v2` - color set to `black`
- `iter8/reviews:istio-v3` - color set to `red`
- `iter8/reviews:istio-v4` - color set to `yellow` (and introduces a 5s delay)
