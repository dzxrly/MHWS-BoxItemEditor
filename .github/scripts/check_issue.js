module.exports = async ({github, context, core}) => {
    try {
        const issue = context.payload.issue;
        const body = issue.body || "";
        const title = (issue.title || "").toLowerCase();

        console.log(`Checking Issue #${issue.number}: ${title}`);

        // 1. 定义匹配规则 (正则)
        // 匹配包含 "Issue Description" 且后面跟着 "问题描述" 的行，忽略大小写
        const bugTemplatePattern = /Issue Description.*问题描述/i;

        // 2. 检查是否匹配
        const isBugReportTemplate = bugTemplatePattern.test(body);
        console.log("Is Bug Report Template?", isBugReportTemplate);

        // 3. 定义 Bug 关键词
        const bugKeywords = [
            "crash", "error", "exception", "not working", "fail", "bug",
            "崩溃", "报错", "错误", "无法运行", "闪退", "失效"
        ];

        // 4. 逻辑判断
        if (!isBugReportTemplate) {
            const lowerBody = body.toLowerCase();
            const hasBugKeywords = bugKeywords.some(keyword =>
                title.includes(keyword) || lowerBody.includes(keyword)
            );

            if (hasBugKeywords) {
                console.log("Detected bug keywords in non-bug template. Sending warning...");

                await github.rest.issues.createComment({
                    owner: context.repo.owner,
                    repo: context.repo.repo,
                    issue_number: issue.number,
                    body: "⚠️ **Format Warning / 格式警告**\n\n" +
                        "It seems you are reporting a bug but not using the **Bug Report** template.\n" +
                        "If this is indeed a bug, please close this issue and open a new one using the correct template to provide versions and logs.\n\n" +
                        "看起来您正在反馈一个 Bug，但没有使用 **Bug report / 问题报告** 模板。\n" +
                        "如果是 Bug，请关闭此 Issue 并使用正确的模板重新提交，以便提供必要的版本和日志信息。"
                });
            } else {
                console.log("No bug keywords detected. Ignoring.");
            }
        } else {
            console.log("Valid Bug Report template detected.");
        }

    } catch (error) {
        console.error("Script failed with error:", error);
        core.setFailed(`Action failed: ${error.message}`);
    }
};