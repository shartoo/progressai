allprojects {
    repositories {
        // 优先使用官方仓库以确保依赖可用性
        google()
        mavenCentral()
        // 阿里云 Maven 仓库作为备用
        maven { setUrl("https://maven.aliyun.com/repository/google") }
        maven { setUrl("https://maven.aliyun.com/repository/public") }
        maven { setUrl("https://maven.aliyun.com/repository/jcenter") }
    }
}

// 完全移除自定义构建目录配置以避免路径冲突
// 使用默认的构建目录

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
