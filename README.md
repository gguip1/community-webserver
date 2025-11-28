# Community Webserver

개발용으로 사용하는 Nginx 웹서버 도커 이미지입니다.

## issues

### main 브랜치에 대한 CD 워크플로우가 동작하지 않는 문제

- workflow_run으로 트리거되는 워크플로우 파일은 반드시 기본 브랜치(default branch) 에 있어야 실행된다.
