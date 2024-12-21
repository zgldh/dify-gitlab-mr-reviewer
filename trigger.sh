# 自动调用 Dify Workflow 
# 日志和配置
LOG_DIR="./logs"
LOG_FILE="dify_monitor.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 确保响应目录存在
mkdir -p "$LOG_DIR"

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # 控制台输出
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO] $timestamp - $message${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN] $timestamp - $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR] $timestamp - $message${NC}"
            ;;
    esac

    # 写入日志文件
    echo "[$level] $timestamp - $message" >> "$LOG_DIR/$LOG_FILE"
}

# 读取配置
read_config() {
    if [ -z "$DIFY_URL" ] || [ -z "$DIFY_API_KEY" ]; then
        log "ERROR" "缺少必要的环境变量。请确保设置了 DIFY_URL, DIFY_API_KEY"
        exit 1
    fi

    URL="$DIFY_URL"
    ACCESS_TOKEN="$DIFY_API_KEY"
    MAX_RETRIES="${DIFY_MAX_RETRIES:-3}"
    TIMEOUT="${DIFY_TIMEOUT:-1800}"
    MIN_INTERVAL="${DIFY_MIN_INTERVAL:-60}"
}

# 美化 JSON 输出
prettify_json() {
    local input="$1"

    # 尝试使用 jq 格式化
    if echo "$input" | jq empty 2>/dev/null; then
        echo "$input" | jq '.'
    else
        # 如果不是有效 JSON，尝试转义或截断
        if [ ${#input} -gt 500 ]; then
            echo "${input:0:500}..."
        else
            echo "$input"
        fi
    fi
}


# 监控函数
monitor_dify() {
    local retry_count=0

    while true; do
        # 记录开始时间
        local start_time=$(date +%s.%N)

        # 生成响应文件名
        local response_file="$LOG_DIR/response_$(date +%Y%m%d_%H%M%S).json"

        # 发送请求并保存响应
        local http_response
        http_response=$(curl -s -w "%{http_code}:%{time_total}" \
            -m "$TIMEOUT" \
            -X POST "$URL/v1/workflows/run" \
            --header "Authorization: Bearer $ACCESS_TOKEN" \
            --header 'Content-Type: application/json' \
            --data-raw '{ "inputs": {}, "response_mode": "streaming", "user": "node7-AiCodeReview"}' \
            -o "$response_file")

        # 解析响应
        local http_code=$(echo "$http_response" | cut -d':' -f1)
        local total_time=$(echo "$http_response" | cut -d':' -f2)

        # 检查响应
        if [ "$http_code" -ne 200 ]; then
            log "ERROR" "请求失败，HTTP状态码：$http_code"

            # 输出错误响应
            if [ -s "$response_file" ]; then
                log "ERROR" "错误响应体："
                prettify_json "$(cat "$response_file")"
            fi

            # 重试机制
            ((retry_count++))
            if [ $retry_count -ge "$MAX_RETRIES" ]; then
                log "ERROR" "达到最大重试次数，退出"
                exit 1
            fi

            sleep $((retry_count * 10))
            continue
        fi

        # 重置重试计数
        retry_count=0

        # 处理成功响应
        log "INFO" "响应成功，耗时 $(printf "%.0f" "$total_time") 秒"
        log "INFO" "响应体已保存：$response_file"

        # 美化并部分输出响应体
        log "INFO" "响应预览："
        prettify_json "$(head -n 10 "$response_file")"

        # 动态等待时间
        local end_time=$(date +%s.%N)
        local elapsed_time=$(echo "$end_time - $start_time" | bc)
        local wait_time=$(echo "$MIN_INTERVAL - $elapsed_time" | bc)

        if (( $(echo "$wait_time > 0" | bc -l) )); then
            log "INFO" "等待 $wait_time 秒后继续"
            sleep "$wait_time"
        fi

        # 清理过旧的响应文件（保留最近5个）
        find "$LOG_DIR" -type f -name "response_*.json" -print0 | \
        xargs -0 ls -t | tail -n +6 | xargs -I {} rm "{}"
    done
}

# 信号处理
trap 'log "WARN" "收到中断信号，正常退出";exit 0' SIGINT SIGTERM

# 主程序
main() {
    log "INFO" "启动 Dify 监控脚本"

    # 检查依赖
    for cmd in curl jq bc; do
        if ! command -v "$cmd" &> /dev/null; then
            log "ERROR" "缺少依赖：$cmd"
            exit 1
        fi
    done

    # 读取配置
    read_config

    # 开始监控
    monitor_dify
}

# 执行主程序
main
