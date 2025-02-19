<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, shallowRef } from 'vue'
import { storeToRefs } from 'pinia'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'

import CommonAvatar from '#shared/components/CommonAvatar/CommonAvatar.vue'
import CommonUserAvatar from '#shared/components/CommonUserAvatar/CommonUserAvatar.vue'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import { useAccountAvatarDeleteMutation } from '#shared/entities/account/graphql/mutations/accountAvatarDelete.api.ts'
import { useAccountAvatarAddMutation } from '#shared/entities/account/graphql/mutations/accountAvatarAdd.api.ts'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type {
  AccountAvatarUpdatesSubscriptionVariables,
  AccountAvatarUpdatesSubscription,
  Avatar,
  AccountAvatarListQuery,
} from '#shared/graphql/types.ts'
import type { ImageFileData } from '#shared/utils/files.ts'

import {
  convertFileList,
  allowedImageTypesString,
} from '#shared/utils/files.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonDivider from '#desktop/components/CommonDivider/CommonDivider.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import { useBreadcrumb } from '../composables/useBreadcrumb.ts'

import {
  useAccountAvatarListQuery,
  AccountAvatarListDocument,
} from '../graphql/queries/accountAvatarList.api.ts'
import { useAccountAvatarSelectMutation } from '../graphql/mutations/accountAvatarSelect.api.ts'
import { AccountAvatarUpdatesDocument } from '../graphql/subscriptions/accountAvatarUpdates.api.ts'

const { user } = storeToRefs(useSessionStore())

const { breadcrumbItems } = useBreadcrumb(__('Avatar'))

const { notify } = useNotifications()

const application = useApplicationStore()
const apiUrl = String(application.config.api_path)

const { isTouchDevice } = useTouchDevice()

const avatarListQuery = new QueryHandler(useAccountAvatarListQuery())
const avatarListQueryResult = avatarListQuery.result()
const avatarListQueryLoading = avatarListQuery.loading()

avatarListQuery.subscribeToMore<
  AccountAvatarUpdatesSubscriptionVariables,
  AccountAvatarUpdatesSubscription
>({
  document: AccountAvatarUpdatesDocument,
  variables: {
    userId: user.value?.id || '',
  },
  updateQuery: (prev, { subscriptionData }) => {
    if (!subscriptionData.data?.accountAvatarUpdates.avatars) {
      return null as unknown as AccountAvatarListQuery
    }

    return {
      accountAvatarList: subscriptionData.data.accountAvatarUpdates.avatars,
    }
  },
})

const currentAvatars = computed(() => {
  return avatarListQueryResult.value?.accountAvatarList || []
})

const currentDefaultAvatar = computed(() => {
  return currentAvatars.value.find((avatar) => avatar.default)
})

const fileUploadInput = shallowRef<HTMLInputElement>()

const cameraFlyout = useFlyout({
  name: 'avatar-camera-capture',
  component: () =>
    import('../components/PersonalSettingAvatarCameraFlyout.vue'),
})

const cropImageFlyout = useFlyout({
  name: 'avatar-file-upload',
  component: () =>
    import('../components/PersonalSettingAvatarCropImageFlyout.vue'),
})

const storeAvatar = (image: ImageFileData) => {
  if (!image) return

  const addAvatarMutation = new MutationHandler(
    useAccountAvatarAddMutation({
      variables: {
        images: {
          original: image,
          resized: {
            name: 'resized_avatar.png',
            type: 'image/png',
            content: image.content,
          },
        },
      },
      update: (cache, { data }) => {
        if (!data) return

        const { accountAvatarAdd } = data
        if (!accountAvatarAdd?.avatar) return

        const newIdPresent = currentAvatars.value.find((avatar) => {
          return avatar.id === accountAvatarAdd.avatar?.id
        })
        if (newIdPresent) return

        if (currentDefaultAvatar.value) {
          cache.modify({
            id: cache.identify(currentDefaultAvatar.value),
            fields: {
              default() {
                return false
              },
            },
          })
        }

        let existingAvatars = cache.readQuery<AccountAvatarListQuery>({
          query: AccountAvatarListDocument,
        })

        existingAvatars = {
          ...existingAvatars,
          accountAvatarList: [
            ...(existingAvatars?.accountAvatarList || []),
            accountAvatarAdd.avatar,
          ],
        }

        cache.writeQuery({
          query: AccountAvatarListDocument,
          data: existingAvatars,
        })
      },
    }),
    {
      errorNotificationMessage: __('The avatar could not be uploaded.'),
    },
  )

  addAvatarMutation.send().then((data) => {
    if (data?.accountAvatarAdd?.avatar) {
      if (user.value) {
        user.value.image = data.accountAvatarAdd.avatar.imageHash
      }

      notify({
        id: 'avatar-upload-success',
        type: NotificationTypes.Success,
        message: __('Your avatar has been uploaded.'),
      })
    }
  })
}

const addAvatarByUpload = () => {
  fileUploadInput.value?.click()
}

const addAvatarByCamera = () => {
  cameraFlyout.open({
    onAvatarCaptured: (image: ImageFileData) => {
      storeAvatar(image)
    },
  })
}

const loadAvatar = async (input?: HTMLInputElement) => {
  const files = input?.files
  if (!files) return

  const [avatar] = await convertFileList(files)

  cropImageFlyout.open({
    image: avatar,
    onImageCropped: (image: ImageFileData) => storeAvatar(image),
  })

  // Reset input value to allow selecting the same file again
  input.value = ''
}

const selectAvatar = (avatar: Avatar) => {
  const accountAvatarSelectMutation = new MutationHandler(
    useAccountAvatarSelectMutation(() => ({
      variables: { id: avatar.id },
      update(cache) {
        currentAvatars.value.forEach((currentAvatar) => {
          cache.modify({
            id: cache.identify(currentAvatar),
            fields: {
              default() {
                return currentAvatar.id === avatar.id
              },
            },
          })
        })
      },
    })),
    {
      errorNotificationMessage: __('The avatar could not be selected.'),
    },
  )

  accountAvatarSelectMutation.send().then(() => {
    notify({
      id: 'avatar-select-success',
      type: NotificationTypes.Success,
      message: __('Your avatar has been changed.'),
    })
  })
}

const deleteAvatar = (avatar: Avatar) => {
  const accountAvatarDeleteMutation = new MutationHandler(
    useAccountAvatarDeleteMutation(() => ({
      variables: { id: avatar.id },
      update(cache) {
        if (avatar.default) {
          cache.modify({
            id: cache.identify(currentAvatars.value[0]),
            fields: {
              default() {
                return true
              },
            },
          })
        }

        cache.evict({ id: cache.identify(avatar) })
        cache.gc()
      },
    })),
    {
      errorNotificationMessage: __('The avatar could not be deleted.'),
    },
  )

  accountAvatarDeleteMutation.send().then(() => {
    notify({
      id: 'avatar-delete-success',
      type: NotificationTypes.Success,
      message: __('Your avatar has been deleted.'),
    })
  })
}

const { waitForVariantConfirmation } = useConfirmation()

const confirmDeleteAvatar = async (avatar: Avatar) => {
  const confirmed = await waitForVariantConfirmation('delete')

  if (confirmed) deleteAvatar(avatar)
}

const avatarButtonClasses = [
  'cursor-pointer',
  '-:outline-transparent',
  'hover:-:outline-blue-900',
  'rounded-full',
  'outline',
  'outline-3',
  'focus:outline-blue-800',
  'hover:focus:outline-blue-800',
]

const activeAvatarButtonClass = (active: boolean) => {
  return {
    'outline-blue-800 hover:outline-blue-800': active,
  }
}
</script>

<template>
  <LayoutContent :breadcrumb-items="breadcrumbItems">
    <div class="mb-4 max-w-[600px]">
      <CommonLoader :loading="avatarListQueryLoading">
        <CommonLabel class="!mt-0.5 mb-1 !block"
          >{{ $t('Your avatar') }}
        </CommonLabel>

        <div class="rounded-lg bg-blue-200 dark:bg-gray-700">
          <div class="flex flex-row flex-wrap gap-2.5 p-2.5">
            <template v-for="avatar in currentAvatars" :key="avatar.id">
              <button
                v-if="avatar.initial && user"
                :aria-label="$t('Select this avatar')"
                :class="[
                  ...avatarButtonClasses,
                  activeAvatarButtonClass(avatar.default),
                ]"
                @click.stop="avatar.default ? void 0 : selectAvatar(avatar)"
              >
                <CommonUserAvatar
                  :class="{ 'avatar-selected': avatar.default }"
                  :entity="user"
                  class="!flex border-neutral-100 dark:border-gray-900"
                  size="large"
                  initials-only
                  personal
                />
              </button>
              <div
                v-else-if="avatar.imageHash"
                class="group/avatar relative flex"
              >
                <button
                  :aria-label="$t('Select this avatar')"
                  :class="[
                    ...avatarButtonClasses,
                    activeAvatarButtonClass(avatar.default),
                  ]"
                  @click.stop="avatar.default ? void 0 : selectAvatar(avatar)"
                >
                  <CommonAvatar
                    :class="{ 'avatar-selected': avatar.default }"
                    :image="`${apiUrl}/users/image/${avatar.imageHash}`"
                    class="!flex border-neutral-100 dark:border-gray-900"
                    size="large"
                  >
                  </CommonAvatar>
                </button>
                <CommonButton
                  v-if="avatar.deletable"
                  :aria-label="$t('Delete this avatar')"
                  :class="{ 'opacity-0 transition-opacity': !isTouchDevice }"
                  class="absolute -end-2 -top-1 text-white focus:opacity-100 group-hover/avatar:opacity-100"
                  group="avatar"
                  icon="x-lg"
                  size="small"
                  variant="remove"
                  @click.stop="confirmDeleteAvatar(avatar)"
                />
              </div>
            </template>
          </div>

          <CommonDivider padding />

          <div class="w-full p-1 text-center">
            <input
              ref="fileUploadInput"
              :accept="allowedImageTypesString()"
              aria-hidden="true"
              class="hidden"
              data-test-id="fileUploadInput"
              type="file"
              @change="loadAvatar(fileUploadInput)"
            />

            <CommonButton
              class="m-1"
              size="medium"
              prefix-icon="image"
              @click="addAvatarByUpload"
            >
              {{ $t('Upload') }}
            </CommonButton>

            <CommonButton
              class="m-1"
              size="medium"
              prefix-icon="camera"
              @click="addAvatarByCamera"
            >
              {{ $t('Camera') }}
            </CommonButton>
          </div>
        </div>
      </CommonLoader>
    </div>
  </LayoutContent>
</template>
