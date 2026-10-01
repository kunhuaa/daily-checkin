#!/bin/bash
# 每日签到汇总脚本
# 支持多平台签到并发送飞书通知

set -e

# ==================== 配置区 ====================
# 请根据实际情况修改以下配置

# 飞书 Webhook（必填）
FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_HOOK_ID"

# 青龙面板地址（可选，默认本地）
QL_HOST="http://localhost:5700"
QL_TOKEN=""

# 日志文件
LOG_FILE="./logs/checkin_$(date +%Y%m%d).log"

# ==================== 函数定义 ====================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_feishu() {
    local message="$1"
    local tmpfile=$(mktemp)
    
    # 转义特殊字符
    local escaped_msg=$(echo "$message" | sed 's/"/\\"/g' | sed 's/\n/\\n/g')
    
    cat > "$tmpfile" << JSONEOF
{
    "msg_type": "text",
    "content": {
        "text": "$escaped_msg"
    }
}
JSONEOF
    
    curl -s -X POST "$FEISHU_WEBHOOK" \
        -H "Content-Type: application/json" \
        -d @"$tmpfile" --max-time 10
    
    rm -f "$tmpfile"
}

random_delay() {
    # 随机延迟 2-5 秒，防风控
    sleep $((RANDOM % 4 + 2))
}

# ==================== 签到函数 ====================

sign_baiduwp() {
    log "🔄 百度网盘签到..."
    # 调用青龙面板签到脚本
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/baiduwp/main.py 2>&1 || echo "签到失败"
}

sign_bilibili() {
    log "🔄 Bilibili签到..."
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/bilibili/main.py 2>&1 || echo "签到失败"
}

sign_enshan() {
    log "🔄 恩山论坛签到..."
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/enshan/main.py 2>&1 || echo "签到失败"
}

sign_kgqq() {
    log "🔄 全民K歌签到..."
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/kgqq/main.py 2>&1 || echo "签到失败"
}

sign_tieba() {
    log "🔄 百度贴吧签到..."
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/tieba/main.py 2>&1 || echo "签到失败"
}

sign_alist() {
    log "🔄 阿里云盘签到..."
    docker exec qinglong python3 /ql/data/repo/Sitoi_dailycheckin_main/dailycheckin/aliyun/main.py 2>&1 || echo "签到失败"
}

sign_wps() {
    log "🔄 WPS签到..."
    # WPS签到需要配置Cookie
    docker exec qinglong env WPS_COOKIE="$WPS_COOKIE" python3 /ql/data/scripts/wps_signin.py 2>&1 || echo "签到失败"
}

sign_ms_rewards() {
    log "🔄 微软积分签到..."
    # 微软积分通过容器日志获取结果
    docker logs microsoft-rewards --tail 20 2>&1 || echo "签到失败"
}

# ==================== 主函数 ====================

main() {
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log "========================================"
    log "📅 每日签到开始 - $(date '+%Y-%m-%d %H:%M:%S')"
    log "========================================"
    
    declare -a RESULTS
    
    # 执行各平台签到
    RESULTS+=("百度网盘|$(sign_baiduwp)")
    random_delay
    
    RESULTS+=("Bilibili|$(sign_bilibili)")
    random_delay
    
    RESULTS+=("恩山论坛|$(sign_enshan)")
    random_delay
    
    RESULTS+=("全民K歌|$(sign_kgqq)")
    random_delay
    
    RESULTS+=("阿里云盘|$(sign_alist)")
    random_delay
    
    RESULTS+=("百度贴吧|$(sign_tieba)")
    random_delay
    
    RESULTS+=("WPS签到|$(sign_wps)")
    random_delay
    
    RESULTS+=("微软积分|$(sign_ms_rewards)")
    
    # 汇总结果
    log ""
    log "========================================"
    log "📊 签到结果汇总"
    log "========================================"
    
    local notify_text="📋 **每日签到结果** - $(date '+%m-%d')\n\n"
    
    for result in "${RESULTS[@]}"; do
        local name="${result%%|*}"
        local output="${result#*|}"
        local status="✅"
        
        if echo "$output" | grep -qE "失败|Error|error|超时|过期"; then
            status="❌"
        elif echo "$output" | grep -qE "重复|已签到|今日已"; then
            status="⚠️"
        fi
        
        local detail
        detail=$(echo "$output" | grep -E "签到|成功|积分|经验|余额|分" | head -1 | cut -c1-50)
        [ -z "$detail" ] && detail="执行完成"
        
        log "$status $name: $detail"
        notify_text+="${status} ${name}\n   ${detail}\n\n"
    done
    
    notify_text+="⏰ $(date '+%H:%M:%S')"
    
    # 发送飞书通知
    log ""
    log "📧 发送飞书通知..."
    send_feishu "$notify_text"
    log "✅ 通知已发送"
    
    log "========================================"
    log "🎉 签到完成"
    log "========================================"
}

# 运行主函数
main
