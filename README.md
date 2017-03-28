# OpenCV Docker container for coverity.com builds

## Prepare

- Run `./deploy.sh`
- [Download](https://scan.coverity.com/download/linux64) coverity tool package into `data/downloads` directory
- Edit `deploy/env.sh`
- Run `./update_container.sh`

## Run build

```
$ docker start -ai opencv_coverity_ubuntu14.04
```

Container will:
- start
- process necessary build steps
- upload results (if key is specified)
- and then will terminate automatically
