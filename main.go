package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"time"
)

// version is set at build time via ldflags: -X main.version=v1.2.3
var version = "dev"

const repo = "ognistyi/goplatform"

type githubRelease struct {
	TagName string `json:"tag_name"`
}

func checkUpdate() {
	if version == "dev" {
		return
	}

	client := &http.Client{Timeout: 3 * time.Second}
	resp, err := client.Get("https://api.github.com/repos/" + repo + "/releases/latest")
	if err != nil {
		return
	}
	defer resp.Body.Close()

	var release githubRelease
	if err := json.NewDecoder(resp.Body).Decode(&release); err != nil {
		return
	}

	if release.TagName != "" && release.TagName != version {
		fmt.Printf("\nНова версія доступна: %s -> %s\n", version, release.TagName)
		fmt.Printf("Оновити: curl -fsSL https://raw.githubusercontent.com/%s/main/install.sh | sh\n", repo)
	}
}

func main() {
	fmt.Printf(" >>> Platform: %s/%s\n", runtime.GOOS, runtime.GOARCH)
	fmt.Printf("     Version:  %s\n", version)
	checkUpdate()
}
