import { common } from '@kit.AbilityKit'
import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { notificationManager } from '@kit.NotificationKit'
import { WorkoutStorageService } from './WorkoutStorageService'

const ONE_DAY_SECONDS = 24 * 60 * 60

export class ReminderService {
  private static instance: ReminderService

  static getInstance(): ReminderService {
    if (!ReminderService.instance) {
      ReminderService.instance = new ReminderService()
    }
    return ReminderService.instance
  }

  async scheduleTomorrow(context: common.UIAbilityContext): Promise<number> {
    await this.ensureNotifications(context)

    const reminder: reminderAgentManager.ReminderRequestTimer = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
      triggerTimeInSeconds: ONE_DAY_SECONDS,
      title: await context.resourceManager.getStringValue($r('app.string.reminder_title').id),
      content: await context.resourceManager.getStringValue($r('app.string.reminder_content').id),
      expiredContent: await context.resourceManager.getStringValue($r('app.string.reminder_expired_content').id),
      ringDuration: 5
    }

    const reminderId = await reminderAgentManager.publishReminder(reminder)
    await WorkoutStorageService.getInstance().saveReminderId(context, reminderId)
    return reminderId
  }

  async cancelSavedReminder(context: common.UIAbilityContext): Promise<void> {
    const reminderId = await WorkoutStorageService.getInstance().loadReminderId(context)
    if (reminderId >= 0) {
      await reminderAgentManager.cancelReminder(reminderId)
      await WorkoutStorageService.getInstance().saveReminderId(context, -1)
    }
  }

  private async ensureNotifications(context: common.UIAbilityContext): Promise<void> {
    const enabled = await notificationManager.isNotificationEnabled()
    if (!enabled) {
      await notificationManager.requestEnableNotification(context)
    }
    await notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION)
  }
}
