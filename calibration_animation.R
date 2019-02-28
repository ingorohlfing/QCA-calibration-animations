#' ---
#' title: "Animated plots for calibration in Qualitative Comparative Analysis"
#' author: "Ingo Rohlfing"
#' date: ""
#' output:
#'    html_document
#' ---

#' The plots created in this script are stored in a subfolder `figures`. If one
#' wants to execute this script, one first needs to create a subfolder `figures`
#' in the folder in which this R script is stored.
#'
#' Loading packages. All packages need to be installed if they have
#' not been installed already. The package `grateful` is not needed
#' for the execution of the code. It generates the references for the other,
#' essential packages.
#+ packages, message = F
library(dplyr) # install.packages("dplyr")
library(tidyr) # install.packages("tidyr")
library(tibble) # install.packages("tibble")
library(ggplot2) # install.packages("ggplot2")
library(gganimate) # install.packages("gganimate")
library(QCA) # install.packages("QCA")
library(grateful) # see https://github.com/Pakillo/grateful

#' ## Direct calibration for fuzzy sets
#' Generating hypothetical data.
#+ hypothetical data
# reproducible sampling
set.seed(4829576) 
# sampling variable
hypdata <- tibble(var_A = runif(30, min = 1, max = 100))
# calibrating condition
original <- hypdata %>%
  arrange(desc(var_A)) %>% 
  mutate(calibrated = calibrate(var_A, thresholds = c(25, 50, 70)), # hypothetical original anchors
         uncalibrated = 0, # baseline X-value for animation
         flatline = 0) # baseline Y-value for animation
# stacking data
directcal <- gather(original, datatype, value, uncalibrated, calibrated) 

#' Creating horizontal lines for set inclusion degree of membership 
#' (`idm` option for `calibrate()` function) and vertical lines for
#' specified variable values.
#+ lines
directcal <- directcal %>% 
  mutate(excl_hor = case_when(datatype == "calibrated" ~ 0.05), # exclusion membership
         excl_ver = case_when(datatype == "calibrated" ~ 25), # exclusion anchor
         cross_hor = case_when(datatype == "calibrated" ~ 0.5), # cross-over membership
         cross_ver = case_when(datatype == "calibrated" ~ 50), # cross-over anchor
         incl_hor = case_when(datatype == "calibrated" ~ 0.95), # inclusion membership
         incl_ver = case_when(datatype == "calibrated" ~ 70)) # inclusion anchor

#' ### Direct calibration with default settings
#' Plot for non-calibrated variable.
#+ non-calibrated variable
ggplot(data = directcal, aes(x = var_A, y = flatline)) +
  geom_point(size = 1) +
  scale_y_continuous("calibrated set A", limits = c(0, 1)) +
  scale_x_continuous("variable A") + 
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 10),
        axis.text = element_text(size = 10))
ggsave("figures/uncalibrated_static.png")

#' Static plot with calibrated variable as input for animation.
#+ non-animated plot condition, warning = F
static_cal <- ggplot(data = directcal) +
  geom_point(aes(x = var_A, y = value)) + 
  geom_hline(aes(yintercept = excl_hor), color = "#E69F00", size = 0.75) +
  geom_vline(aes(xintercept = excl_ver), color = "#E69F00", size = 0.75) +
  geom_hline(aes(yintercept = cross_hor), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = cross_ver), color = "#56B4E9", size = 0.75) +
  geom_hline(aes(yintercept = incl_hor), color = "#CC79A7", size = 0.75) +
  geom_vline(aes(xintercept = incl_ver), color = "#CC79A7", size = 0.75) +
  scale_y_continuous("calibrated set A", limits = c(0, 1)) +
  scale_x_continuous("variable A") +
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 16))

#' Meaning of horizontal lines:
#' 
#' * top, purple line: inclusion degree membership for `A` 
#' * middle, blue line: cross-over point for `A`
#' * bottom, orange line: exclusion degree membership for `A`
#' 
#' Meaning of vertical lines:
#' 
#'  * right, purple line: full membership anchor / 1-anchor at 70
#'  * middle, blue line: cross-over anchor / 0.5-anchor at 50
#'  * left, orange line: full non-membership anchor / 0-anchor at 25
#'
#+ dynamic plot condition
anim_cal <- static_cal + 
  transition_states(datatype,
                    transition_length = 0.75,
                    state_length = 1) +
  ggtitle('Showing {closest_state}') +
  theme(title = element_text(size = 20))
animate(anim_cal, width = 650, height = 650)
anim_save("figures/direct_calibration.gif")     

#' ### Recalibrating anchors
#' Calibration with different anchors for full membership, cross-over point
#' and full non-membership. Specification of hypothetical, alternative anchors.
#+ recalibrating anchors
recalibrated <- original %>% 
  select(var_A, calibrated) %>% 
  mutate(inclhigher = calibrate(var_A, thresholds = "25, 50, 80"), # higher 1-anchor
         incllower = calibrate(var_A, thresholds = "25, 50, 60"), # lower 1-anchor
         crosshigher = calibrate(var_A, thresholds = "25, 60, 70"), # higher 0.5-anchor
         crosslower = calibrate(var_A, thresholds = "25, 40, 70"), # lower 0.5-anchor
         exclhigher = calibrate(var_A, thresholds = "35, 50, 70"), # higher 0-anchor
         excllower = calibrate(var_A, thresholds = "15, 50, 70")) # higher 0-anchor
recalibrated <- gather(recalibrated, anchor, value, 
                       calibrated, 
                       inclhigher, incllower,
                       crosshigher, crosslower,
                       exclhigher, excllower)

#' Data preparation for alternative *inclusion* anchors.
#+ alternative inclusion
incl_recal <- recalibrated %>% 
  mutate(incl_hor = 0.95,
         incl_ver = case_when(anchor == "calibrated" ~ 70,
                              anchor == "inclhigher" ~ 80,
                              anchor == "incllower" ~ 60)) %>% 
  mutate(anchor = case_when(
    anchor == "calibrated" ~ "original 1-anchor",
    anchor == "inclhigher" ~ "higher 1-anchor",
    anchor == "incllower" ~ "lower 1-anchor"))
    
#' Static plot for three different *inclusion* anchors for animation.
#+ upper anchor static
static_incl_recal <- ggplot(data = incl_recal) +
  geom_hline(aes(yintercept = incl_hor), color = "#CC79A7", size = 0.75) +
  geom_vline(aes(xintercept = incl_ver), color = "#CC79A7", size = 0.75) +
  geom_hline(aes(yintercept = 0.5), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = 50), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = 70), color = "gray", size = 0.75) +
  geom_point(aes(x = var_A, y = value)) + 
  scale_y_continuous("calibrated set A", limits = c(0, 1)) +
  scale_x_continuous("variable A") +
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 16))

#' Animated plot for three different *inclusion* anchors. The static, gray
#' line marks the originally chosen anchor.
#+ upper anchor animated, warning = F
anim_incl_recal <- static_incl_recal + 
  transition_states(anchor,
                    transition_length = 0.75,
                    state_length = 1) +
  ggtitle('Showing {closest_state}') +
  theme(title = element_text(size = 20))
animate(anim_incl_recal, width = 650, height = 650)
anim_save("figures/incl_recalibration.gif")  

#' Data preparation for alternative *exclusion* anchors.
#+ alternative exclusion
excl_recal <- recalibrated %>% 
  mutate(excl_hor = 0.05,
         excl_ver = case_when(anchor == "calibrated" ~ 25,
                              anchor == "exclhigher" ~ 35,
                              anchor == "excllower" ~ 15)) %>% 
  mutate(anchor = case_when(
    anchor == "calibrated" ~ "original 0-anchor",
    anchor == "exclhigher" ~ "higher 0-anchor",
    anchor == "excllower" ~ "lower 0-anchor"))

#' Static plot for three different *exclusion* anchors for animation.
#+ exclusion static
static_excl_recal <- ggplot(data = excl_recal) +
  geom_hline(aes(yintercept = excl_hor), color = "#E69F00", size = 0.75) +
  geom_vline(aes(xintercept = excl_ver), color = "#E69F00", size = 0.75) +
  geom_hline(aes(yintercept = 0.5), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = 50), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = 25), color = "gray", size = 0.75) +
  geom_point(aes(x = var_A, y = value)) + 
  scale_y_continuous("calibrated set A", limits = c(0, 1)) +
  scale_x_continuous("variable A") +
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 16))

#' Animated plot for three different *exclusion* anchors. The static, gray
#' line marks the originally chosen anchor.
#+ upper anchor animated, warning = F
anim_excl_recal <- static_excl_recal + 
  transition_states(anchor,
                    transition_length = 0.75,
                    state_length = 1) +
  ggtitle('Showing {closest_state}') +
  theme(title = element_text(size = 20))
animate(anim_excl_recal, width = 650, height = 650)
anim_save("figures/excl_recalibration.gif")  

#' Data preparation for alternative *cross-over* anchors.
#+ alternative cross-over
cross_recal <- recalibrated %>% 
  mutate(cross_hor = 0.5,
         cross_ver = case_when(anchor == "calibrated" ~ 50,
                               anchor == "crosshigher" ~ 60,
                               anchor == "crosslower" ~ 40)) %>% 
  mutate(anchor = case_when(
    anchor == "calibrated" ~ "original 0.5-anchor",
    anchor == "crosshigher" ~ "higher 0.5-anchor",
    anchor == "crosslower" ~ "lower 0.5-anchor"))

#' Static plot for three different *cross-over* anchors for animation.
#+ upper anchor static
static_cross_recal <- ggplot(data = cross_recal) +
  geom_hline(aes(yintercept = cross_hor), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = cross_ver), color = "#56B4E9", size = 0.75) +
  geom_vline(aes(xintercept = 50), color = "gray", size = 0.75) +
  geom_point(aes(x = var_A, y = value)) + 
  scale_y_continuous("calibrated set A", limits = c(0, 1)) +
  scale_x_continuous("variable A") +
  theme_bw() +
  theme(panel.grid = element_blank(),
        axis.title = element_text(size = 16),
        axis.text = element_text(size = 16))

#' Animated plot for three different *cross-over* anchors. The static, gray
#' line marks the originally chosen anchor.
#+ upper anchor animated, warning = F
anim_cross_recal <- static_cross_recal + 
  transition_states(anchor,
                    transition_length = 0.75,
                    state_length = 1) +
  ggtitle('Showing {closest_state}') +
  theme(title = element_text(size = 20))
animate(anim_cross_recal, width = 650, height = 650)
anim_save("figures/cross_recalibration.gif") 
