# Non-localized strings (discovered round 1)

## by file

### lib/screens/home_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 97   | "Camera" | camera | (reuse) bottom sheet row label |
| 121  | "Gallery" | gallery | (reuse) bottom sheet row label |
| 315  | "Change" | change_photo | Change photo chip |
| 364  | "Redesign your\nspace" | home_hero_title | Hero CTA title |
| 374  | "AI-powered magic for your room" | home_hero_subtitle | Hero CTA subtitle |
| 392  | "Recent Projects" | home_recent_projects | Section header |
| 413, 466 | "View All" | view_all | Section action |
| 449  | "Discover Styles" | home_discover_styles | Section header |
| 840  | "Tap to explore" | home_tap_explore | Category card subtitle |
| 918, 1026 | "Design" | design_fallback_name | Fallback style name (dynamic) |
| 949-951, 957, 1060 | "Updated Xm/h/d ago", "Jan..Dec" months | (skip) date/time formatting, not simple UI strings |

### lib/screens/before_after_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 50   | "ERROR" | error_label | Image error label (uppercase) |
| 72   | "Retry" | retry | (reuse) Retry button in error state |
| 183  | "Check out my AI redesigned room!" | share_design_text | Share sheet text |
| 187  | "Failed to share: $e" | share_failed | Snackbar on share error (uses prefix) |
| 199  | "Redesigned" | redesigned_fallback | Fallback style name |
| 230  | "Architectural AI" | (skip - brand) | App title in AppBar |
| 259  | "AI POWERED" | ai_powered | Badge |
| 292  | "Your space transformed..." | before_after_subtitle | Dynamic subtitle (style name interpolated) |
| 339  | "BEFORE" | before | (reuse) |
| 351  | "AFTER" | after | (reuse) |
| 405  | "Saved" | saved | (reuse) |
| 406  | "Save" | save | (reuse) |
| 428  | "Share" | share | (reuse) |
| 474  | "Create Better Version" | create_better_version | CTA |
| 482  | "50% OFF" | fifty_percent_off | Discount badge |

### lib/screens/history_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 265  | "Design" | design_fallback_name | (reuse) |

### lib/screens/home_shell.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 83   | "Create" | nav_create | Bottom nav label |
| 155  | "CREATE" | (derived from nav_create.toUpperCase()) | Prominent CTA label - will use .toUpperCase() |

### lib/screens/inspiration_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 236  | world.name | (dynamic) | - |
| 238  | "Select a room photo to transform" | select_room_photo | Bottom sheet subtitle |
| 245, 261 | "Camera"/"Gallery" | camera/gallery | (reuse) |
| 299  | "All Collections" | all_collections | App bar title |
| 321  | "No worlds found for this collection" | no_worlds_found | Empty state |
| 336  | "Explore $category themed rooms. Tap to transform your space." | inspiration_explore_desc | Dynamic |
| 382  | "All Options" | all_options | Subsection header |
| 470  | "${worlds.length} worlds" | worlds_count | Dynamic subtitle |
| 551  | "NEW" | new_badge | NEW badge |

### lib/screens/onboarding_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 209  | "Get Started"/"Next" | get_started / next | (reuse - both already exist) |
| 220  | "By continuing, you agree to our Terms of Service..." | onboarding_terms_notice | Legal notice |
| 258  | "1000+ Design Themes" | onboarding_themes_title | Page 1 title |
| 267  | "From minimalist zen..." | onboarding_themes_desc | Page 1 desc |
| 368  | "1 TOKEN PER STYLE" | token_per_style | Badge |
| 430  | "SAVED" | saved_badge | Image badge |
| 464  | "ON-DEVICE STORAGE" | on_device_storage | Storage info label |
| 473  | "100% Private" | fully_private | Storage info |
| 492  | "Your Vision, AI Powered" | onboarding_vision_title | Page 2 title |
| 503  | "Simply snap a photo..." | onboarding_vision_desc | Page 2 desc |
| 513  | "1000+ Unique architectural styles" | onboarding_feature_styles | Feature check |
| 515  | "Token-based generation system" | onboarding_feature_tokens | Feature check |
| 627  | "ICONIC WORLDS" | iconic_worlds_badge | Badge |
| 686  | "Iconic Worlds Await" | iconic_worlds_title | Page 3 title |
| 692  | "Transform your room into $names..." | iconic_worlds_desc | Page 3 desc |
| 810  | "Interactive Demo" | interactive_demo | (reuse) |
| 820  | "Try it yourself." | try_yourself | Page 4 title |
| 829  | "Tap a style, then slide to compare." | tap_style_slide | Page 4 desc |
| 997  | "Generating..." | generating | Shimmer overlay |
| 1024 | "ORIGINAL" | original_badge | Tag |
| 1101 | "Choose from 1000+ unique styles. Renders use 1 token each." | onboarding_demo_info | Footer |

### lib/screens/processing_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 41-48 | HP-themed messages | (skip - themed narratives, complex) |
| 55-63 | Matrix messages | (skip) |
| 69-76 | Post-apoc messages | (skip) |
| 82-91 | Clean/modern messages | (skip) |
| 96-106 | Default tips | (skip - many dynamic phrases) |
| 153  | "Unknown" | (skip) internal arg to notification |
| 194  | "Failed to create design" | create_design_failed | Snackbar error |
| 262  | "AI Redesign" | ai_redesign | (reuse) |
| 412  | "2 tokens will be used for this render" | tokens_will_be_used | Footer note |
| 486  | "Enjoying Architectural AI?" | enjoying_app | Rating dialog title |
| 492  | "Your design is ready! Rate your experience to help us improve." | rating_dialog_desc | Dialog body |
| 530  | "Rate & See Your Design" | rate_see_design | CTA |
| 545  | "Maybe Later" | maybe_later | (reuse) |

Note on processing messages: the long list of themed rotation messages is ignored per instructions — treated as narrative/content, not simple UI labels. A per-language agent can lift these later.

### lib/screens/purchase_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 113  | "Purchase successful!" | purchase_success | Snackbar |
| 113  | "Purchase could not be completed." | purchase_failed | Snackbar |
| 127  | "Restoring purchases..." | restoring_purchases | Snackbar |
| 137  | "Purchases restored successfully!" | purchases_restored | Snackbar |
| 138  | "No purchases found to restore." | no_purchases_found | Snackbar |
| 176  | "Go Premium" | go_premium | Tab |
| 177  | "Buy Tokens" | buy_tokens | Tab |
| 242  | "Upgrade & Tokens" | upgrade_tokens_title | Header title |
| 251  | "Go Premium for the best experience, or just top up tokens." | upgrade_tokens_subtitle | Header subtitle |
| 262  | "Restore" | restore | Restore button |
| 312  | "No subscriptions available" | no_subscriptions | Empty state |
| 313, 407 | "Please check your App Store / Play Store configuration." | check_store_config | Empty state subtitle |
| 332  | "+100 tokens / month" | bonus_100_tokens_month | Bonus label |
| 333  | "Subscribe" | subscribe | CTA |
| 340  | "Subscriptions renew automatically..." | subscriptions_renew_notice | Footer |
| 351  | "Billed yearly • Best value" | billed_yearly | Subscription subtitle |
| 353  | "Billed monthly" | billed_monthly | Subscription subtitle |
| 354  | "Billed weekly" | billed_weekly | Subscription subtitle |
| 406  | "No token packs available" | no_token_packs | Empty state |
| 424  | "Buy" | buy | (reuse) |
| 438  | "$tokens tokens" | tokens_count | Dynamic label (uses %s) |
| 581  | "MOST POPULAR" | most_popular | (reuse) |
| 624  | "Premium benefits" | premium_benefits | Benefits banner |
| 634  | "+100 monthly tokens included" | benefit_monthly_tokens | Benefit row |
| 636  | "Access every premium style & world" | benefit_all_styles | Benefit row |
| 638  | "Best-quality model on every render" | benefit_best_quality | Benefit row |
| 640  | "No ads, no watermarks" | benefit_no_ads | Benefit row |
| 689  | "Failed to load packages" | failed_load_packages | Error state title |
| 698  | "Please try again in a moment." | try_again_moment | Error state subtitle |
| 708  | "Retry" | retry | (reuse) |

### lib/screens/result_detail_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 81   | "ERROR" | error_label | (reuse) |
| 98   | "Tap to retry" | tap_to_retry | Error state |
| 157  | "No image available to export" | no_image_export | Snackbar |
| 193  | "Saved to Photos" | saved_to_photos | Snackbar |
| 207  | "Failed to save: ..." | save_failed | Snackbar prefix |
| 223  | "Japandi" | (skip, fallback value) | - (never displayed without value) |
| 242  | "Result Detail" | result_detail | (reuse) |
| 282  | "Want to redesign another room?" | redesign_another | (reuse) |
| 308  | "New Room" | new_room | (reuse) |
| 351  | "AI Enhanced" | ai_enhanced | (reuse) |
| 374  | "New Photo" | new_photo | (reuse) |
| 390  | "New Style" | new_style | (reuse) |
| 403  | "Share" | share | (reuse) |
| 422  | "My AI redesigned room!" | share_design_short | Share prompt |
| 451  | "Saving..." / "Export High-Res" | saving / export_hires | Button states |
| 483  | "Create Better Version" | create_better_version | (reuse) |
| 485  | "50% OFF" | fifty_percent_off | (reuse) |
| 499  | "Recommended Styles" | recommended_styles | Section header |
| 510  | "Based on your recent designs" | recommended_desc | Section subtitle |

### lib/screens/settings_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 101  | "Could not open App Store. Please try again." | app_store_open_failed | Snackbar |
| 121  | "+$granted tokens added — thanks for reviewing!" | review_tokens_thanks | Snackbar (prefix) |
| 122  | "Reward not yet available." | reward_not_available | Snackbar |
| 140  | "Reward ready — tap to claim +%s tokens" | review_reward_ready | Row subtitle |
| 146  | "Reward activates 1h after review" | review_reward_waiting | Row subtitle |
| 152  | "Review and get +%s tokens (activates in 1h)" | review_reward_invite | Row subtitle |
| 168  | "Need help? We\'re here for you!" | help_line_intro | Help dialog |
| 170  | "Email: support@architecturai.app" | (skip - literal email) | - |
| 171  | "Response time: Within 24 hours" | help_response_time | Help dialog |
| 173  | "FAQ topics:" | faq_topics | Help dialog |
| 175  | "  - How to use tokens" | faq_how_tokens | Help dialog |
| 176  | "  - Design quality tips" | faq_quality_tips | Help dialog |
| 177  | "  - Account & billing" | faq_account_billing | Help dialog |
| 183  | "OK" | ok | (reuse) |
| 202  | "We typically respond within 24 hours." | contact_response | Contact dialog |
| 224-232 | privacy policy text | privacy_policy_body | Dialog body |
| 254-262 | terms of service text | terms_of_service_body | Dialog body |
| 293  | "Account deletion request submitted..." | account_deletion_submitted | Snackbar |
| 307  | "Restoring purchases..." | restoring_purchases | (reuse) |
| 321  | "Purchases restored successfully!" | purchases_restored | (reuse) |
| 322  | "No purchases found to restore." | no_purchases_found | (reuse) |
| 331  | "Failed to restore purchases. Please try again." | restore_purchases_failed | Snackbar |
| 398  | "Token Balance" | token_balance | Label |
| 407  | "${n} tokens" | tokens_count | (reuse) |
| 425  | "-X pending" | pending_deduction | Badge prefix |
| 441  | "Premium: +X tokens / month" | premium_monthly_tokens | Premium subtitle (dynamic) |
| 462  | "Get More" | get_more | Tokens CTA |
| 483  | "+10 test tokens added" | (skip - debug) | - |
| 489  | "Add 10 test tokens (debug)" | (skip - debug) | - |
| 579  | "Active — includes X monthly tokens" | premium_active_subtitle | Settings row subtitle |
| 723  | "Reset Onboarding" | reset_onboarding | Danger row |
| 724  | "Start fresh (for testing)" | reset_onboarding_desc | Danger row subtitle |
| 1060 | "Premium Member" | premium_member | Premium status card |
| 1060 | "Free Plan" | free_plan | (reuse) |
| 1071 | "Upgrade to get 100 monthly tokens and premium styles" | upgrade_subtitle | Premium card CTA |
| 1091 | "Manage"/"Upgrade" | manage / upgrade | Premium card button |
| 1106 | "Premium benefits active" | premium_benefits_active | Subtitle |
| 1108 | "Includes X monthly tokens" | includes_monthly_tokens | Subtitle |
| 1117 | "Next X-token grant available" | next_grant_available | Subtitle |
| 1119 | "Includes X tokens/month • next in Nd" | includes_tokens_next_in | Subtitle |

### lib/screens/splash_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 93   | "Architectural AI" | (skip - brand) | - |
| 104  | "Your dream space, within your\nreach." | splash_tagline | Tagline |
| 141  | "INITIALIZING AI ENGINE" | splash_initializing | Progress label |
| 156  | "POWERED BY AI" | splash_powered_by_ai | Footer |

### lib/screens/store_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 285  | "Select Your Room Photo" | select_room_photo_title | Sheet title |
| 294  | "Your room will be transformed into this style" | transform_subtitle | Sheet subtitle |
| 307, 318 | "Camera"/"Gallery" | camera/gallery | (reuse) |
| 362  | "Failed to pick image: $e" | pick_image_failed | Snackbar prefix |
| 423  | "Cancel" | cancel | (reuse) |
| 436  | "Unlock for $price" | unlock_for | CTA (dynamic price) |
| 448  | "Get PRO for unlimited access" | get_pro_cta | Footer button |
| 472  | "Store" | store | (reuse) |
| 492  | "Search worlds..." | search_worlds_hint | TextField hint |
| 559  | "Free for PRO members" | free_for_pro | Pro banner |
| 567  | "Unlock all Specialty Worlds" | unlock_all_worlds | Pro banner subtitle |
| 592  | "Upgrade\nto PRO" | upgrade_to_pro | Button |
| 618  | "Specialty Worlds" | specialty_worlds | Section title |
| 627  | "Immersive themes for your next masterpiece." | specialty_worlds_desc | Section subtitle |
| 697  | "No worlds found" | no_worlds_search | Empty state |
| 812  | "NEW" | new_badge | (reuse) |

### lib/screens/style_selection_screen.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 166  | "Select Your Room Photo" | select_room_photo_title | (reuse) |
| 175  | "Take a new photo or choose from gallery" | take_or_choose_photo | Subtitle |
| 187, 198 | "Camera"/"Gallery" | camera/gallery | (reuse) |
| 233  | "Failed to pick image: $e" | pick_image_failed | (reuse) |
| 292  | "STEP X OF Y" | step_x_of_y | Title format |
| 446  | "Capture Your Space" | capture_space | Step 0 title |
| 451  | "Every great redesign begins with a clear vision..." | capture_space_desc | Step 0 desc |
| 482  | "Change" | change_photo | (reuse) |
| 523  | "Live Camera" | live_camera | Capture option |
| 525  | "AI-assisted viewfinder for perfect results" | live_camera_desc | Capture option desc |
| 564  | "Photo Gallery" | photo_gallery | Capture option |
| 566  | "Select high-res shots from library" | photo_gallery_desc | Capture option desc |
| 581  | "PRO CAPTURE TIPS" | pro_capture_tips | Section header |
| 585  | "Natural Lighting" / "Shoot during the golden hour..." | tip_lighting_title / tip_lighting_desc | Tip |
| 587  | "Wide Angles" / "Stand in a corner..." | tip_angles_title / tip_angles_desc | Tip |
| 589  | "Clear Clutter" / "Remove small objects..." | tip_clutter_title / tip_clutter_desc | Tip |
| 596, 979, 1222 | "Next" | next | (reuse) |
| 902  | "Choose Your Aesthetic" | choose_aesthetic | Step 1 title |
| 911  | "Select the mood that defines your dream space." | choose_aesthetic_desc | Step 1 desc |
| 926  | "Design" | tab_design | Tab label |
| 927  | "World" | tab_world | Tab label |
| 1001 | "Refine Vision" | refine_vision | Step 2 title |
| 1010 | "Add the final artistic touches to your AI redesign instructions." | refine_vision_desc | Step 2 desc |
| 1042 | "Custom Instructions" | custom_instructions | Card title |
| 1051 | "Costs 2x tokens for personalized results" | custom_instructions_desc | Card subtitle |
| 1085 | "Describe the mood, lighting..." | custom_prompt_hint | TextField hint |
| 1105 | "QUICK SUGGESTIONS" | quick_suggestions | Section label |
| 1153 | "Choose Quality" | choose_quality | Section title |
| 1166-1167 | "Standard" / "Great for quick previews" | quality_standard / quality_standard_desc | Option |
| 1173-1174 | "Ultra HD" / "Maximum detail & fidelity" | quality_ultra_hd / quality_ultra_hd_desc | Option |
| 1181-1182 | "PRO+" / "Our best model — premium results" | quality_pro_plus / quality_pro_plus_desc | Option |
| 1204 | "Pro Tip" | pro_tip | Banner |
| 1207 | "Combining descriptive scene references..." | pro_tip_desc | Banner text |
| 1343 | "Standard"/"PRO+"/"Ultra HD" | quality_* | (reuse) |
| 1361 | "Review Selection" | review_selection | Step 3 title |
| 1372 | "Original" | original | (reuse) |
| 1419 | "Tap to add a photo" | tap_add_photo | Empty state |
| 1438 | "ORIGINAL CANVAS" | original_canvas | Badge |
| 1473 | "Style" | style_label | Summary label |
| 1518 | "None" | none | Fallback |
| 1547 | "Quality" | quality | Summary label |
| 1600 | "Custom Instructions" | custom_instructions | (reuse) |
| 1636 | "Base Transformation" | base_transformation | Token row |
| 1638 | "Custom Instructions (x2)" | custom_instructions_2x | Token row |
| 1649 | "TOTAL TOKENS" | total_tokens | Total row |
| 1694 | "You need X tokens but only have Y. Buy more to continue." | not_enough_tokens_msg | Warning (dynamic) |
| 1713 | "Get More Tokens" | get_more_tokens | CTA |
| 1722 | "Select Photo First"/"Start Design" | select_photo_first / start_design | CTA |
| 1739 | " TOKENS" | tokens_suffix | Amount suffix label |

### lib/widgets/app_card.dart, section_header.dart, skeleton_loader.dart, token_badge.dart, image_placeholder.dart
These widgets only render dynamic caller-supplied strings or fixed structural text. Only widget literal found:
- `lib/widgets/image_placeholder.dart:39` "Preview" → `preview` (image placeholder fallback)
- `lib/widgets/token_badge.dart:25` "$tokens tokens" — uses `tokens_count` (reuse)

### lib/widgets/rating_dialog.dart
| line | literal | new_key | context |
|------|---------|---------|---------|
| 165  | "10 TOKENS FREE" | ten_tokens_free | Gift badge |
| 179  | "Rate Your Design! ⭐" | rate_design | (reuse base) - emoji kept in string |
| 188  | "How did the AI transformation turn out?\nRate now and get 10 free tokens!" | rate_design_compound | Combined copy |
| 272  | "Submit & Get Tokens" | submit_get_tokens | (reuse) |
| 296  | "Maybe Later" | maybe_later | (reuse) |
| 319-328 | rating texts | rating_1..rating_5 | Star feedback |

## new keys (flat list for translator agents)

- change_photo: "Change"
- home_hero_title: "Redesign your\nspace"
- home_hero_subtitle: "AI-powered magic for your room"
- home_recent_projects: "Recent Projects"
- view_all: "View All"
- home_discover_styles: "Discover Styles"
- home_tap_explore: "Tap to explore"
- design_fallback_name: "Design"
- error_label: "ERROR"
- share_design_text: "Check out my AI redesigned room!"
- share_failed: "Failed to share"
- redesigned_fallback: "Redesigned"
- ai_powered: "AI POWERED"
- before_after_subtitle: "Your space transformed with %s aesthetic — a beautiful blend of style and functionality."
- create_better_version: "Create Better Version"
- fifty_percent_off: "50% OFF"
- nav_create: "Create"
- select_room_photo: "Select a room photo to transform"
- all_collections: "All Collections"
- no_worlds_found: "No worlds found for this collection"
- inspiration_explore_desc: "Explore %s themed rooms. Tap to transform your space."
- all_options: "All Options"
- worlds_count: "%s worlds"
- new_badge: "NEW"
- onboarding_terms_notice: "By continuing, you agree to our Terms of Service and Privacy Policy regarding local data handling."
- onboarding_themes_title: "1000+ Design Themes"
- onboarding_themes_desc: "From minimalist zen to cyberpunk neon — explore an endless library of AI-powered styles or create your own unique aesthetic."
- token_per_style: "1 TOKEN PER STYLE"
- saved_badge: "SAVED"
- on_device_storage: "ON-DEVICE STORAGE"
- fully_private: "100% Private"
- onboarding_vision_title: "Your Vision, AI Powered"
- onboarding_vision_desc: "Simply snap a photo of any room and watch our AI transform it instantly. Customize every detail with natural language instructions."
- onboarding_feature_styles: "1000+ Unique architectural styles"
- onboarding_feature_tokens: "Token-based generation system"
- iconic_worlds_badge: "ICONIC WORLDS"
- iconic_worlds_title: "Iconic Worlds Await"
- iconic_worlds_desc: "Transform your room into %s and many more. 1000+ themed universes to explore."
- try_yourself: "Try it yourself."
- tap_style_slide: "Tap a style, then slide to compare."
- generating: "Generating..."
- original_badge: "ORIGINAL"
- onboarding_demo_info: "Choose from 1000+ unique styles. Renders use 1 token each."
- create_design_failed: "Failed to create design"
- tokens_will_be_used: "2 tokens will be used for this render"
- enjoying_app: "Enjoying Architectural AI?"
- rating_dialog_desc: "Your design is ready! Rate your experience to help us improve."
- rate_see_design: "Rate & See Your Design"
- purchase_success: "Purchase successful!"
- purchase_failed: "Purchase could not be completed."
- restoring_purchases: "Restoring purchases..."
- purchases_restored: "Purchases restored successfully!"
- no_purchases_found: "No purchases found to restore."
- go_premium: "Go Premium"
- buy_tokens: "Buy Tokens"
- upgrade_tokens_title: "Upgrade & Tokens"
- upgrade_tokens_subtitle: "Go Premium for the best experience, or just top up tokens."
- restore: "Restore"
- no_subscriptions: "No subscriptions available"
- check_store_config: "Please check your App Store / Play Store configuration."
- bonus_100_tokens_month: "+100 tokens / month"
- subscribe: "Subscribe"
- subscriptions_renew_notice: "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period."
- billed_yearly: "Billed yearly • Best value"
- billed_monthly: "Billed monthly"
- billed_weekly: "Billed weekly"
- no_token_packs: "No token packs available"
- tokens_count: "%s tokens"
- premium_benefits: "Premium benefits"
- benefit_monthly_tokens: "+100 monthly tokens included"
- benefit_all_styles: "Access every premium style & world"
- benefit_best_quality: "Best-quality model on every render"
- benefit_no_ads: "No ads, no watermarks"
- failed_load_packages: "Failed to load packages"
- try_again_moment: "Please try again in a moment."
- tap_to_retry: "Tap to retry"
- no_image_export: "No image available to export"
- saved_to_photos: "Saved to Photos"
- save_failed: "Failed to save"
- share_design_short: "My AI redesigned room!"
- saving: "Saving..."
- recommended_styles: "Recommended Styles"
- recommended_desc: "Based on your recent designs"
- app_store_open_failed: "Could not open App Store. Please try again."
- review_tokens_thanks: "tokens added — thanks for reviewing!"
- reward_not_available: "Reward not yet available."
- review_reward_ready: "Reward ready — tap to claim +%s tokens"
- review_reward_waiting: "Reward activates 1h after review"
- review_reward_invite: "Review and get +%s tokens (activates in 1h)"
- help_line_intro: "Need help? We're here for you!"
- help_response_time: "Response time: Within 24 hours"
- faq_topics: "FAQ topics:"
- faq_how_tokens: "  - How to use tokens"
- faq_quality_tips: "  - Design quality tips"
- faq_account_billing: "  - Account & billing"
- contact_response: "We typically respond within 24 hours."
- privacy_policy_body: "Your privacy is important to us.\n\nWe collect minimal data necessary to provide our service:\n- Device identifier for account management\n- Photos you upload (processed and deleted within 24h)\n- Usage analytics to improve the app\n\nWe do not sell your personal data to third parties.\n\nFor the full privacy policy, visit:\nhttps://architecturai.app/privacy"
- terms_of_service_body: "By using this app, you agree to our Terms of Service.\n\nKey points:\n- Tokens are non-refundable once used\n- Generated designs are for personal use\n- We reserve the right to modify pricing\n- Abuse of the service may result in account suspension\n\nFor the full terms, visit:\nhttps://architecturai.app/terms"
- account_deletion_submitted: "Account deletion request submitted. You will receive a confirmation email."
- restore_purchases_failed: "Failed to restore purchases. Please try again."
- token_balance: "Token Balance"
- pending_deduction: "-%s pending"
- premium_monthly_tokens: "Premium: +%s tokens / month"
- get_more: "Get More"
- premium_active_subtitle: "Active — includes %s monthly tokens"
- reset_onboarding: "Reset Onboarding"
- reset_onboarding_desc: "Start fresh (for testing)"
- premium_member: "Premium Member"
- upgrade_subtitle: "Upgrade to get 100 monthly tokens and premium styles"
- manage: "Manage"
- upgrade: "Upgrade"
- premium_benefits_active: "Premium benefits active"
- includes_monthly_tokens: "Includes %s monthly tokens"
- next_grant_available: "Next %s-token grant available"
- includes_tokens_next_in: "Includes %s tokens/month • next in %sd"
- splash_tagline: "Your dream space, within your\nreach."
- splash_initializing: "INITIALIZING AI ENGINE"
- splash_powered_by_ai: "POWERED BY AI"
- select_room_photo_title: "Select Your Room Photo"
- transform_subtitle: "Your room will be transformed into this style"
- pick_image_failed: "Failed to pick image"
- unlock_for: "Unlock for %s"
- get_pro_cta: "Get PRO for unlimited access"
- search_worlds_hint: "Search worlds..."
- free_for_pro: "Free for PRO members"
- unlock_all_worlds: "Unlock all Specialty Worlds"
- upgrade_to_pro: "Upgrade\nto PRO"
- specialty_worlds: "Specialty Worlds"
- specialty_worlds_desc: "Immersive themes for your next masterpiece."
- no_worlds_search: "No worlds found"
- step_x_of_y: "STEP %s OF %s"
- capture_space: "Capture Your Space"
- capture_space_desc: "Every great redesign begins with a clear vision. Show us your room."
- take_or_choose_photo: "Take a new photo or choose from gallery"
- live_camera: "Live Camera"
- live_camera_desc: "AI-assisted viewfinder for perfect results"
- photo_gallery: "Photo Gallery"
- photo_gallery_desc: "Select high-res shots from library"
- pro_capture_tips: "PRO CAPTURE TIPS"
- tip_lighting_title: "Natural Lighting"
- tip_lighting_desc: "Shoot during the golden hour or mid-day for the most accurate color reproduction in your space."
- tip_angles_title: "Wide Angles"
- tip_angles_desc: "Stand in a corner to capture the full layout. AI needs to see where walls meet the floor."
- tip_clutter_title: "Clear Clutter"
- tip_clutter_desc: "Remove small objects from surfaces for a cleaner mapping and more realistic furniture placement."
- choose_aesthetic: "Choose Your Aesthetic"
- choose_aesthetic_desc: "Select the mood that defines your dream space."
- tab_design: "Design"
- tab_world: "World"
- refine_vision: "Refine Vision"
- refine_vision_desc: "Add the final artistic touches to your AI redesign instructions."
- custom_instructions: "Custom Instructions"
- custom_instructions_desc: "Costs 2x tokens for personalized results"
- custom_prompt_hint: "Describe the mood, lighting, or specific artistic details you want to see..."
- quick_suggestions: "QUICK SUGGESTIONS"
- choose_quality: "Choose Quality"
- quality_standard: "Standard"
- quality_standard_desc: "Great for quick previews"
- quality_ultra_hd: "Ultra HD"
- quality_ultra_hd_desc: "Maximum detail & fidelity"
- quality_pro_plus: "PRO+"
- quality_pro_plus_desc: "Our best model — premium results"
- pro_tip: "Pro Tip"
- pro_tip_desc: "Combining descriptive scene references like \"Cozy Dusk\" or \"Vintage Summer\" keeps the AI focused and produces more coherent results."
- review_selection: "Review Selection"
- tap_add_photo: "Tap to add a photo"
- original_canvas: "ORIGINAL CANVAS"
- style_label: "Style"
- none: "None"
- quality: "Quality"
- base_transformation: "Base Transformation"
- custom_instructions_2x: "Custom Instructions (x2)"
- total_tokens: "TOTAL TOKENS"
- not_enough_tokens_msg: "You need %s tokens but only have %s. Buy more to continue."
- get_more_tokens: "Get More Tokens"
- select_photo_first: "Select Photo First"
- tokens_suffix: " TOKENS"
- preview: "Preview"
- ten_tokens_free: "10 TOKENS FREE"
- rate_design_compound: "How did the AI transformation turn out?\nRate now and get 10 free tokens!"
- rating_1: "Not great 😔"
- rating_2: "Could be better 🤔"
- rating_3: "Pretty good! 👍"
- rating_4: "Love it! 😍"
- rating_5: "Amazing! Perfect! 🤩"

## Deliberately ignored / out of scope

- Debug print messages and `debugPrint(...)` strings
- `throw Exception(...)` messages
- Themed rotation messages in `processing_screen.dart` (lines 41-106) — large narrative content blocks; recommend future round specifically for them
- Asset paths (e.g. `ios/Runner/Assets.xcassets/...`), route names (`'/styles'`, `'/home'`), URLs
- Brand names: "Architectural AI", "Architectural AI" title repetitions
- Email addresses (`support@architecturai.app`) and web URLs — literal
- Date-relative "Updated Xm ago" format strings and month abbreviation arrays in home_screen.dart and history_screen.dart (line 949-957, 1055-1061, 295-299) — complex date formatting, should be handled by a localized date formatter, out of scope for string swap
- Debug-only strings behind `kDebugMode` in settings_screen (lines 483, 489)
- Single-character separators / emojis only
