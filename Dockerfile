# 1단계: 빌드 이미지 생성
FROM gradle:8.3-jdk17 AS builder

# 작업 디렉토리 생성
WORKDIR /app

# 종속성 캐싱 단계: Gradle 설정 파일만 복사 후 빌드 실행
COPY --chown=gradle:gradle build.gradle settings.gradle /app/
RUN gradle build --no-daemon || return 0

# 소스 파일을 컨테이너에 복사
COPY --chown=gradle:gradle . /app

# 프로젝트 빌드 (JAR 파일 생성)
RUN gradle clean bootJar

# 2단계: 런타임 이미지 생성
# 최신 Ubuntu Jammy Jellyfish (22.04 LTS) 기반의 OpenJDK 17 이미지를 사용합니다.
# eclipse-temurin 이미지는 Adoptium에서 제공하며, 안정적입니다.
FROM eclipse-temurin:17-jdk-jammy

# healthcheck를 위해 curl 설치
# Ubuntu 기반 이미지이므로 apt-get을 사용하여 curl을 설치할 수 있습니다.
RUN apt-get update -y && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 빌드에서 생성된 JAR 파일을 런타임 이미지에 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 애플리케이션 포트 설정
EXPOSE 8080

# 애플리케이션 실행 명령어
ENTRYPOINT ["java", "-jar", "/app.jar"]
