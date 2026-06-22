/// 应用字符串常量（统一管理，便于未来国际化）
class AppStrings {
  AppStrings._();

  // === 通用 ===
  static const String appTitle = 'FirstCC';
  static const String appSubtitle = '大学生课程表+待办管理';
  static const String ok = '确定';
  static const String cancel = '取消';
  static const String confirm = '确认';
  static const String save = '保存';
  static const String delete = '删除';
  static const String edit = '编辑';
  static const String add = '添加';
  static const String retry = '重试';
  static const String loading = '加载中...';
  static const String noData = '暂无数据';

  // === 启动页 ===
  static const String splashInit = '正在初始化...';
  static const String splashInitNotify = '正在初始化通知服务...';
  static const String splashLoadData = '正在加载数据...';
  static const String splashSeedData = '正在导入课表数据...';
  static const String splashImportShared = '正在导入分享的课表...';
  static const String splashInitFailed = '初始化失败';

  // === 课程表 ===
  static const String scheduleHeaderNoSemester = '未设置学期';
  static const String scheduleToday = '今天';
  static const String scheduleDayView = '日视图';
  static const String scheduleEmptyWeek = '本周没有课程';
  static const String scheduleEmptySubtitle = '点击右下角按钮添加课程';
  static const String scheduleEmptyDay = '当天没有课程';
  static const String schedulePleaseSetSemester = '请先设置学期';
  static const String scheduleSetSemesterHint = '在设置中添加一个学期开始使用';

  // === 课程 ===
  static const String courseManagement = '课程管理';
  static const String courseManageAll = '管理所有课程';
  static const String courseAdd = '添加课程';
  static const String courseEdit = '编辑课程';
  static const String courseName = '课程名称';
  static const String courseTeacher = '教师';
  static const String courseClassroom = '教室';
  static const String courseTimeArrangement = '时间安排';
  static const String courseDayOfWeek = '上课日期';
  static const String courseStartPeriod = '起始节';
  static const String courseDuration = '持续';
  static const String courseStartWeek = '起始周';
  static const String courseEndWeek = '结束周';
  static const String courseWeekType = '周次类型';
  static const String courseColor = '颜色';
  static const String courseNotes = '备注';
  static const String courseSave = '保存课程';
  static const String courseNameHint = '高等数学A(一)';
  static const String courseTeacherHint = '张三';
  static const String courseClassroomHint = '教一楼A101';
  static const String courseNotesHint = '教材、网站链接等';
  static const String courseNameRequired = '请输入课程名称';
  static const String courseNoSemester = '请先设置当前学期';
  static const String courseDetailTitle = '课程详情';
  static const String courseInfo = '基本信息';
  static const String courseSchedule = '排课信息';
  static const String courseBoundTodos = '关联待办';
  static const String courseNoBoundTodos = '暂无关联待办';
  static const String courseAddTodo = '添加待办';

  // === 待办 ===
  static const String todoAdd = '添加待办';
  static const String todoEdit = '编辑待办';
  static const String todoTitle = '任务名称';
  static const String todoTitleHint = '完成高数作业 P45-P48';
  static const String todoTitleRequired = '请输入任务名称';
  static const String todoDescription = '备注';
  static const String todoDescriptionHint = '可选的详细描述';
  static const String todoPriority = '优先级';
  static const String todoDueDate = '截止日期';
  static const String todoDueTime = '添加时间';
  static const String todoClearTime = '清除时间';
  static const String todoBoundCourse = '关联课程';
  static const String todoNoBoundCourse = '无关联课程';
  static const String todoReminder = '提醒设置';
  static const String todoSave = '保存任务';
  static const String todoComplete = '完成';
  static const String todoIncomplete = '未完成';
  static const String todoDetailTitle = '待办详情';
  static const String todoCreatedAt = '创建时间';
  static const String todoCompletedAt = '完成时间';
  static const String todoDueInfo = '截止信息';
  static const String todoPriorityLabels = '优先级';

  // === 待办筛选 ===
  static const String filterAll = '全部';
  static const String filterIncomplete = '未完成';
  static const String filterCompleted = '已完成';
  static const String filterHighPriority = '高优先级';
  static const String filterOverdue = '逾期';

  // === 语音添加待办 ===
  static const String voiceAddTitle = '语音添加待办';
  static const String voiceHint = '长按开始录音';
  static const String voiceListening = '正在聆听...';
  static const String voiceStartFailed = '启动语音识别失败，请重试';
  static const String voiceNoContent = '未识别到语音内容';
  static const String voiceNoTask = '未检测到待办任务，请重新录音';
  static const String voiceRetry = '重新录音';
  static const String voiceRecognizedText = '识别文本';
  static String voiceSaveAll(int count) => '全部保存 ($count 条)';
  static String voiceSaved(int count) => '已保存 $count 条待办';
  static const String voiceAddManual = '手动添加';
  static const String voiceAddVoice = '语音添加';

  // === 模型下载 ===
  static const String modelDownloadTitle = '下载离线语音模型';
  static const String modelDownloadDesc =
      '首次使用语音识别需要下载中文语音模型（约 82 MB），'
      '建议在 WiFi 环境下进行。\n下载后即可完全离线使用。';
  static const String modelDownloadStart = '开始下载';
  static const String modelDownloading = '正在下载模型...';
  static const String modelDownloadFailed = '模型下载失败，请检查网络后重试';

  // === 学期 ===
  static const String semesterManagement = '学期管理';
  static const String semesterNew = '新建学期';
  static const String semesterEdit = '编辑学期';
  static const String semesterName = '学期名称';
  static const String semesterNameHint = '2025-2026学年第一学期';
  static const String semesterStartDate = '开学日期';
  static const String semesterEndDate = '结束日期';
  static const String semesterTotalWeeks = '总周数';
  static const String semesterSetCurrent = '设为当前学期';
  static const String semesterDeleteTitle = '删除学期';
  static const String semesterDeleteContent = '删除后课程将被删除，关联的待办将解除课程绑定。此操作不可撤销。';
  static const String semesterDeleteConfirm = '删除';
  static const String semesterNone = '还没有学期';
  static const String semesterNoneHint = '添加一个新学期开始规划课程吧';

  // === 设置 ===
  static const String settingsTitle = '设置';
  static const String settingsTheme = '主题模式';
  static const String settingsLight = '浅色';
  static const String settingsDark = '深色';
  static const String settingsSystem = '系统';
  static const String settingsAbout = '关于';
  static const String settingsImport = '导入课表';
  static const String settingsImportDesc = '从选课网导出的 .xls 文件导入';
  static const String settingsVersion = 'v1.0.0';
  static const String settingsDescription = '轻量化 · 无广告 · 极简高效';
  static const String settingsNotSetSemester = '未设置学期';

  // === 课表导入 ===
  static const String importParsing = '正在解析课表...';
  static const String importImporting = '正在导入课程...';
  static const String importNoCourses = '未解析到任何课程';
  static const String importConfirmTitle = '确认导入课表';
  static const String importSemester = '学期';
  static const String importCourseCount = '课程数';
  static const String importWarnings = '注意事项';
  static const String importConfirmBtn = '确认导入';
  static const String importSuccessTitle = '导入成功';
  static const String importSuccessMsg = '已导入 {count} 门课程\n学期：{semester}';
  static const String importFailedTitle = '导入失败';
  static const String importDefaultName = '导入的课表';
  static const String importTableNotFound = '未找到课表表格，请确认文件格式正确';
  static const String importNoCellData = '未找到课程数据，表格中无 infoTitle 单元格';

  // === 通知 ===
  static const String notifyReminderTitle = '⏰ 任务提醒';
  static const String notifyChannelName = '课程提醒';
  static const String notifyChannelDesc = '上课、作业截止、考试提醒';
  static const String notifyTodoChannelName = '任务提醒';
  static const String notifyTodoChannelDesc = '待办任务截止提醒';

  // === 周次类型 ===
  static const String weekTypeEvery = '每周';
  static const String weekTypeOdd = '单周';
  static const String weekTypeEven = '双周';

}
