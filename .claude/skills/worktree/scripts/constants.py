"""
Worktree SKILL 常數定義

集中管理所有魔法數字、字面值和配置常數。
"""

# ===== 分支前綴常數 =====

# feat/ 前綴長度，用於 extract_ticket_id_from_branch 中去掉前綴
FEAT_PREFIX = "feat/"
FEAT_PREFIX_LEN = len(FEAT_PREFIX)  # 5


# ===== 保護分支常數 =====
#
# H1 修復：統一使用 git_utils.py 的版本（支援 glob 模式，更完整）
# git_utils 版本: ["main", "master", "develop", "release/*", "production"]
# 常數引用自 git_utils，此處僅保留向後相容別名
# 若需修改，請更新 .claude/lib/git_utils.py 中的定義
#
# from git_utils import PROTECTED_BRANCHES 不可用（避免循環依賴）
# 使用者應直接使用 worktree_manager 或 git_utils 提供的函式，不直接訪問此常數
PROTECTED_BRANCHES = ["main", "master", "develop"]  # 已棄用，使用 git_utils 版本


# ===== 允許編輯的分支模式 =====
#
# H2 修復：統一使用 git_utils.py 的版本（支援更多 glob 模式）
# git_utils 版本:
#   - "feat/*", "feature/*", "fix/*", "hotfix/*", "bugfix/*"
#   - "chore/*", "docs/*", "refactor/*", "test/*"
# 常數引用自 git_utils，此處僅保留向後相容別名
ALLOWED_BRANCH_PATTERNS = ["feat/", "feature/", "fix/", "hotfix/"]  # 已棄用，使用 git_utils 版本


# ===== Ticket ID 正則表達式 =====

# #3 修復：統一使用官方版本的 TICKET_ID_PATTERN
# 來源：.claude/skills/ticket/ticket_system/lib/constants.py (v0.31.0 及更高版本)
# 此常數提供給 worktree SKILL 使用，避免重複定義
#
# 支援無限深度子任務和描述性後綴
# 格式: {version}-W{wave}-{seq[.seq...]}[-description]
# 範例:
#   0.31.0-W3-001           (根任務)
#   0.31.0-W3-001.1         (第一層子任務)
#   0.31.0-W3-001.1.1       (第二層子任務)
#   0.1.0-W11-004-phase1-design  (TDD Phase 文件)
#   0.1.0-W25-005-analysis       (分析文件)
TICKET_ID_PATTERN = r"^(\d+\.\d+\.\d+)-W(\d+)-(\d+(?:\.\d+)*)(-[a-z0-9][a-z0-9-]{0,59})?$"


# ===== Worktree 相關常數 =====

WORKTREE_STATUS_OUTPUT_WIDTH = 50  # 狀態輸出寬度（分隔線）
DEFAULT_BASE_BRANCH = "main"  # create 子命令預設基礎分支


# ===== merge 子命令常數 =====

# ticket track 查詢超時秒數（避免 merge 流程卡住）
TICKET_QUERY_TIMEOUT = 5

# Ticket 已完成的狀態值
TICKET_COMPLETED_STATUS = "completed"


# ===== cleanup 子命令常數 =====

# cleanup 輸出寬度（與 status 使用相同常數）
CLEANUP_OUTPUT_WIDTH = WORKTREE_STATUS_OUTPUT_WIDTH

# git branch -d 失敗時，提示使用者的強制刪除指令中的 flag
BRANCH_FORCE_DELETE_FLAG = "-D"
