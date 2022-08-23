## ----setup--------------------------------------------------------------------
.libPaths("/mnt/data/donald/R/x86_64-pc-linux-gnu-library/4.1")

suppressMessages(library(tidyverse))
library(stringr)
library(xtable)
suppressMessages(library(extrafont))
library(fontcm)


## ----dirs---------------------------------------------------------------------
env_data_root <- Sys.getenv("ANALYSIS_DATA_ROOT")
if (env_data_root != "") {
  data_root <- env_data_root
} else {
  data_root <- "../permanently_saved_results/apr-10-more-combos"
}

perf_root <- str_c(data_root, "/perf")
oldness_root <- str_c(data_root, "/oldness")
sizes_root <- str_c(data_root, "/sizes")


results_root <- str_c(data_root, "/number-results")
dir.create(results_root, showWarnings = FALSE)

tables_dir <- str_c(data_root, "/tables")
dir.create(tables_dir, showWarnings = FALSE)

plots_dir <- str_c(data_root, "/plots")
dir.create(plots_dir, showWarnings = FALSE)


results_tex <- str_c(results_root, "/results.tex")

write("% These are results from the R Notebook.", results_tex, append=FALSE)
write("% Run the notebook from top to bottom", results_tex, append=TRUE)


## -----------------------------------------------------------------------------
mytheme <- function() {
  return(theme_bw() +
           theme(
             # NOTE: UNCOMMENT WHEN RENDING PLOTS FOR THE PAPER
             # (can't get the CM fonts to work in artifact VM...)
             text = element_text(family = "CM Roman", size=10),
              panel.grid.major = element_blank(),
             # panel.grid.minor = element_blank(),
             # panel.grid.major = element_line(colour="gray", size=0.1),
             # panel.grid.minor =
             #  element_line(colour="gray", size=0.1, linetype='dotted'),
             axis.ticks = element_line(size=0.05),
             axis.ticks.length=unit("-0.05", "in"),
             axis.text.y = element_text(margin = margin(r = 5)),
             axis.text.x = element_text(hjust=1),
             legend.key = element_rect(colour=NA),
             legend.spacing = unit(0.001, "in"),
             legend.key.size = unit(0.2, "in"),
             legend.title = element_blank(),
             legend.position = c(0.75, .7),
             legend.background = element_blank()))
}

mysave <- function(filename) {
  path <- str_c(plots_dir, "/", filename)
  ggsave(path, width=4, height=3, units=c("in"))
  # embed_font(path)
}



## -----------------------------------------------------------------------------
raw_data <- read_csv(paste(data_root, "/results.csv", sep=""),
  col_types = cols(Status=col_factor(),
                   Project=col_factor(),
                   Rosette=col_logical(),
                   Consistency=col_factor(),
                   DisallowCycles=col_factor(),
                   Minimize=col_factor(),
                   Time=col_double(),
                   # CVE=col_double(),
                   NDeps=col_integer()),
  show_col_types = FALSE)
                   


## -----------------------------------------------------------------------------
levels(raw_data$Status)


## -----------------------------------------------------------------------------
levels(raw_data$Consistency)


## -----------------------------------------------------------------------------
levels(raw_data$Minimize)


## -----------------------------------------------------------------------------
levels(raw_data$DisallowCycles)


## -----------------------------------------------------------------------------
num_experiments <- raw_data %>% 
  # group_by(Rosette,AuditFix,Minimize,Consistency,DisallowCycles) %>%
  group_by(Rosette,Minimize,Consistency,DisallowCycles) %>%
  summarize(Count = n()) %>%
  ungroup() %>%
  select(Count) %>%
  unique()
stopifnot(nrow(num_experiments) == 1)
stopifnot(num_experiments[1] == 1000)


## -----------------------------------------------------------------------------
failure_analysis <- raw_data %>% 
  filter(Status != "success") %>%
  # group_by(Rosette,AuditFix,Minimize,Consistency,DisallowCycles) %>%
  group_by(Rosette,Minimize,Consistency,DisallowCycles) %>%
  summarise(Unsat = sum(Status == "unsat"),
            Timeout = sum(Status == "unavailable" | Status == "timeout"),
            Other = sum(Status != "unsat" & Status != "unavailable" & Status != "timeout")) %>%
  ungroup() %>%
  mutate(Solver = if_else(Rosette, "MinNPM", "NPM")) %>%
  rename(Minimization = Minimize) %>%
  select(-Rosette) %>%
  # relocate(Solver,AuditFix,Consistency,DisallowCycles,Minimization,Unsat,Timeout,Other)
  relocate(Solver,Consistency,DisallowCycles,Minimization,Unsat,Timeout,Other)
print(xtable(as.data.frame(failure_analysis), type="latex"), include.rownames=FALSE, file=str_c(tables_dir, "/", "failures.tex"))
knitr::kable(failure_analysis)


## -----------------------------------------------------------------------------
failure_summary <- failure_analysis %>% 
    mutate(Total = Unsat + Timeout + Other) %>%
  # filter((Solver == "NPM" & AuditFix == "no") | Consistency == "npm") %>%
  filter((Solver == "NPM") | Consistency == "npm") %>%
  select(Solver, Total, Consistency) %>%
  group_by(Solver) %>%
  summarize(Min = min(Total), Max = max(Total))
    
write(
  str_c("\\newcommand{\\dataNumNPMFailures}{", 
        failure_summary %>% filter(Solver == "NPM") %>% select(Max),
        "}\n"),
  results_tex, append = TRUE)

write(
  str_c("\\newcommand{\\dataMinMinNPMFailures}{", 
        failure_summary %>% filter(Solver == "MinNPM") %>% select(Min),
        "}\n"),
  results_tex, append = TRUE)

write(
  str_c("\\newcommand{\\dataMaxMinNPMFailures}{", 
        failure_summary %>% filter(Solver == "MinNPM") %>% select(Max),
        "}\n"),
  results_tex, append = TRUE)





## -----------------------------------------------------------------------------
minnpm_timeouts <- failure_analysis %>% 
  filter(Consistency == "npm") %>%
  select(Timeout) %>%
  summarise(Min = min(Timeout), Max = max(Timeout))

minnpm_timeouts

write(
  str_c("\\newcommand{\\dataMinNPMTimesoutsMin}{", 
        minnpm_timeouts$Min,
        "}\n"),
  results_tex, append=TRUE)
write(
  str_c("\\newcommand{\\dataMinNPMTimesoutsMax}{", 
        minnpm_timeouts$Max,
        "}\n"),
  results_tex, append=TRUE)


## -----------------------------------------------------------------------------
pip_unsat_df <- raw_data %>% 
  filter(Rosette == TRUE &
           Consistency == "pip" &
           Minimize == "min_oldness,min_num_deps" &
           DisallowCycles == "allow_cycles" &
           Status == "unsat") %>%
  select(Project) %>%
  inner_join(raw_data %>%
               filter(Rosette == TRUE &
                        Consistency == "npm" &
                        Minimize == "min_oldness,min_num_deps" &
                        DisallowCycles == "allow_cycles" &
                        Status == "success") %>%
               select(Project))
pip_unsat_df

## -----------------------------------------------------------------------------
num_pip_unsat <- nrow(pip_unsat_df)
fraction_pip_unsat <- num_pip_unsat / nrow(raw_data %>%  filter(Rosette == FALSE))

write(
  str_c("\\newcommand{\\dataNumPIPUnsupported}{", 
        round(num_pip_unsat),
        "}\n"),
  results_tex, append=TRUE)

write(
  str_c("\\newcommand{\\dataFractionPIPUnsupported}{", 
        round(fraction_pip_unsat * 100, digits = 1),
        "\\%}\n"),
  results_tex, append=TRUE)


## -----------------------------------------------------------------------------
cargo_unsat_df <- raw_data %>% 
  filter(Rosette == TRUE &
           Consistency == "cargo" &
           Minimize == "min_oldness,min_num_deps" &
           DisallowCycles == "allow_cycles" &
           Status == "unsat") %>%
  select(Project) %>%
  inner_join(raw_data %>%
               filter(Rosette == TRUE &
                        Consistency == "npm" &
                        Minimize == "min_oldness,min_num_deps" &
                        DisallowCycles == "allow_cycles" &
                        Status == "success") %>%
               select(Project))
cargo_unsat_df


## -----------------------------------------------------------------------------
num_cargo_unsat <- nrow(cargo_unsat_df)
fraction_cargo_unsat <- num_cargo_unsat / nrow(raw_data %>%  filter(Rosette == FALSE))

write(
  str_c("\\newcommand{\\dataNumCargoUnsupported}{", 
        round(num_cargo_unsat),
        "}\n"),
  results_tex, append=TRUE)

write(
  str_c("\\newcommand{\\dataFractionCargoUnsupported}{", 
        round(fraction_cargo_unsat * 100, digits = 1),
        "\\%}\n"),
  results_tex, append=TRUE)


## -----------------------------------------------------------------------------
minnpm_fails_npm_succeeds <- raw_data %>% 
  filter(Rosette == TRUE &
           Consistency == "npm" &
           Minimize == "min_oldness,min_num_deps" &
           DisallowCycles == "allow_cycles" &
           Status != "success") %>%
  select(Project, Status) %>%
  inner_join(raw_data %>%
               filter(Rosette == FALSE &
                        Status == "success") %>%
               select(Project))

minnpm_fails_npm_succeeds

num_minnpm_fails_npm_succeeds <- nrow(minnpm_fails_npm_succeeds)
write(
  str_c("\\newcommand{\\dataNumMinNPMFailNPMOk}{", 
        num_minnpm_fails_npm_succeeds,
        "}\n"),
  results_tex, append=TRUE)
num_minnpm_fails_npm_succeeds


## -----------------------------------------------------------------------------
minnpm_succeeds_npm_fails <- raw_data %>% 
  filter(Rosette == TRUE &
           Consistency == "npm" &
           Minimize == "min_oldness,min_num_deps" &
           DisallowCycles == "allow_cycles" &
           Status == "success") %>%
  select(Project, NDeps) %>%
  inner_join(raw_data %>%
               filter(Rosette == FALSE &
                        Status != "success") %>%
               select(Project, Status))

num_minnpm_succeeds_npm_fails <- nrow(minnpm_succeeds_npm_fails)
write(
  str_c("\\newcommand{\\dataNumMinNPMOkNPMFail}{", 
        num_minnpm_succeeds_npm_fails,
        "}\n"),
  results_tex, append=TRUE)
minnpm_succeeds_npm_fails


## -----------------------------------------------------------------------------
min_dep_analysis_tmp <-
  bind_rows(raw_data %>% 
            filter(Rosette == FALSE & Status == "success") %>% 
            select(Project,NDeps) %>% 
            mutate(Solver="NPM"),
          raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_num_deps,min_oldness") %>%
            select(Project, NDeps) %>%
            mutate(Solver="NPM_MinDepsOldness"),
          raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_oldness") %>%
            select(Project, NDeps) %>%
            mutate(Solver="NPM_MinOldness"),
          raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_duplicates,min_oldness") %>%
            select(Project, NDeps) %>%
            mutate(Solver="NPM_MinDuplicatesOldness"),
          raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "pip" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_oldness") %>%
            select(Project, NDeps) %>%
            mutate(Solver="PIP_MinOldness"),
          raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "cargo" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_oldness") %>%
            select(Project, NDeps) %>%
            mutate(Solver="Cargo_MinOldness")) %>%
  pivot_wider(values_from=NDeps, names_from=Solver) %>%
  filter(NPM>0) %>%

  mutate(NPM_NPM_MinDepsOldness_Delta = NPM - NPM_MinDepsOldness) %>%
  mutate(NPM_NPM_MinDepsOldness_Shrinkage = NPM_MinDepsOldness / NPM) %>%

  mutate(NPM_NPM_MinOldness_Delta = NPM - NPM_MinOldness) %>%
  mutate(NPM_NPM_MinOldness_Shrinkage = NPM_MinOldness / NPM) %>%

  mutate(NPM_NPM_MinDuplicatesOldness_Delta = NPM - NPM_MinDuplicatesOldness) %>%
  mutate(NPM_NPM_MinDuplicatesOldness_Shrinkage = NPM_MinDuplicatesOldness / NPM) %>%
  
  mutate(NPM_PIP_MinOldness_Delta = NPM - PIP_MinOldness) %>%
  mutate(NPM_PIP_MinOldness_Shrinkage = PIP_MinOldness / NPM) %>%

  mutate(NPM_Cargo_MinOldness_Delta = NPM - Cargo_MinOldness) %>%
  mutate(NPM_Cargo_MinOldness_Shrinkage = Cargo_MinOldness / NPM) %>%
  
  na.omit()
  
min_dep_analysis_shrinkage <-
  min_dep_analysis_tmp %>%
  pivot_longer(cols = ends_with("Shrinkage"), names_to="shrinkage_comparison", values_to="Shrinkage") %>%
  mutate(Comparison=shrinkage_comparison) %>%
  select(Project,Comparison, Shrinkage)

min_dep_analysis_delta <-
  min_dep_analysis_tmp %>%
  pivot_longer(cols = ends_with("Delta"), names_to="delta_comparison", values_to="Delta") %>%
  mutate(Comparison=delta_comparison) %>%
  select(Project,Comparison, Delta)

min_dep_analysis_shrinkage


## -----------------------------------------------------------------------------
min_dep_analysis_delta %>% 
  filter(Comparison=='NPM_NPM_MinDepsOldness_Delta') %>%
  arrange(desc(Delta)) %>%
  filter(Delta > 25)


## -----------------------------------------------------------------------------
min_dep_analysis_delta %>% arrange(Delta) %>% filter(Delta < 0)


## -----------------------------------------------------------------------------
min_dep_analysis_shrinkage %>% 
  filter(Shrinkage <= 1.0) %>%
  filter(Comparison == "NPM_NPM_MinDepsOldness_Shrinkage" | Comparison == "NPM_NPM_MinOldness_Shrinkage") %>%
  mutate(Comparison = recode(Comparison, 
                             NPM_Cargo_MinOldness_Shrinkage="Cargo",
                             NPM_NPM_MinDepsOldness_Shrinkage="Min Deps",
                             NPM_NPM_MinDuplicatesOldness_Shrinkage="MinDuplicates",
                             NPM_NPM_MinOldness_Shrinkage="Min Oldness",
                             NPM_PIP_MinOldness_Shrinkage="PIP vs. NPM")) %>%
  ggplot(aes(Shrinkage, colour=Comparison)) +
  stat_ecdf() +
  ylab("Percentange of packages") +
  xlab("Fraction of dependencies") +
  mytheme()
mysave("shrinkage.pdf")


## -----------------------------------------------------------------------------
# min_dep_analysis_shrinkage %>% 
#   filter(Shrinkage <= 1.0) %>%
#   filter(Comparison == 'NPM_NPM_MinDepsOldness_Shrinkage') %>%
#   ggplot(aes(Shrinkage)) +
#   geom_histogram(aes(y=..ndensity..),binwidth=0.1) +
#   ylab("Count of packages") +
#   xlab("Fraction of dependencies") +
#   mytheme()
# mysave("shrinkage_hist.pdf")


## -----------------------------------------------------------------------------
group_counts <- min_dep_analysis_shrinkage %>% group_by(Comparison) %>% summarize(n = n())

shrink_group_counts <- min_dep_analysis_shrinkage %>% filter(Shrinkage < 1) %>% group_by(Comparison) %>% summarize(n_shrunk = n())
largen_group_counts <- min_dep_analysis_shrinkage %>% filter(Shrinkage > 1) %>% group_by(Comparison) %>% summarize(n_largen = n())

shrinkage_table <- group_counts %>% 
  inner_join(shrink_group_counts) %>% 
  inner_join(largen_group_counts) %>%
  mutate(percent_shrunk=100 * n_shrunk / n) %>%
  mutate(percent_larger=100 * n_largen / n) %>%
  mutate(Comparison = recode(Comparison, 
                             NPM_Cargo_MinOldness_Shrinkage="Cargo; min_oldness", 
                             NPM_PIP_MinOldness_Shrinkage="PIP; min_oldness",
                             NPM_NPM_MinOldness_Shrinkage="NPM; min_oldness,min_num_deps",
                             NPM_NPM_MinDepsOldness_Shrinkage="NPM; min_num_deps,min_oldness",
                             NPM_NPM_MinDuplicatesOldness_Shrinkage="NPM; min_duplicates,min_oldness")) %>%
  arrange(desc(percent_shrunk)) %>%
  rename('# Shrunk (of 477)' = n_shrunk, '# Enlarged (of 477)' = n_largen, Configuration = Comparison) %>%
  select(Configuration, '# Shrunk (of 477)', '# Enlarged (of 477)')
shrinkage_table

print(xtable(as.data.frame(shrinkage_table), type="latex"), include.rownames=FALSE, file=str_c(tables_dir, "/", "shinkage_combos.tex"))
knitr::kable(shrinkage_table)


## -----------------------------------------------------------------------------
one_comparison <- min_dep_analysis_shrinkage %>% filter(Comparison == 'NPM_NPM_MinDepsOldness_Shrinkage')

fraction_shrinking <- nrow(one_comparison %>% filter(Shrinkage < 1)) / nrow(one_comparison)
write(
  str_c("\\newcommand{\\dataFractionShrinking}{", 
        round(fraction_shrinking * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
fraction_shrinking


## -----------------------------------------------------------------------------
one_comparison_min_old <- min_dep_analysis_shrinkage %>% filter(Comparison == 'NPM_NPM_MinOldness_Shrinkage')

fraction_shrinking_min_old <- nrow(one_comparison_min_old %>% filter(Shrinkage < 1)) / nrow(one_comparison_min_old)
write(
  str_c("\\newcommand{\\dataFractionShrinkingMinOldness}{", 
        round(fraction_shrinking_min_old * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
fraction_shrinking_min_old


## -----------------------------------------------------------------------------
oldness_data <- bind_rows(
  read_csv(paste(oldness_root, "/vanilla.csv", sep=""),
    col_types = cols(Package=col_factor(),
                     Oldness=col_double()),
    show_col_types = FALSE) %>%
    mutate(Solver = "NPM"),
  read_csv(paste(oldness_root, "/rosette-npm-allow_cycles-min_oldness-min_num_deps.csv", sep=""),
    col_types = cols(Package=col_factor(),
                     Oldness=col_double()),
    show_col_types = FALSE) %>%
    mutate(Solver = "MinOldness"),
  read_csv(paste(oldness_root, "/rosette-npm-allow_cycles-min_num_deps-min_oldness.csv", sep=""),
    col_types = cols(Package=col_factor(),
                     Oldness=col_double()),
    show_col_types = FALSE) %>%
    mutate(Solver = "MinNumDeps")) %>%
  mutate(Project=Package) %>%
  select(Project,Oldness,Solver)


## -----------------------------------------------------------------------------
oldness_by_pkg <- oldness_data %>% 
  pivot_wider(values_from = Oldness, names_from=Solver)

npm_success_non_trivial <- raw_data %>% 
  filter(Rosette == FALSE & Status == "success") %>% 
  filter(NDeps > 0) %>%
  select(Project)

min_oldenss_success_non_trivial <- raw_data %>% 
  filter(Rosette == TRUE & 
           Status == "success" & 
           Consistency == "npm" & 
           DisallowCycles == "allow_cycles" & 
           Minimize == "min_oldness,min_num_deps") %>% 
  filter(NDeps > 0) %>%
  select(Project)

min_num_deps_success_non_trivial <- raw_data %>% 
  filter(Rosette == TRUE & 
           Status == "success" & 
           Consistency == "npm" & 
           DisallowCycles == "allow_cycles" & 
           Minimize == "min_num_deps,min_oldness") %>% 
  filter(NDeps > 0) %>%
  select(Project)

all_success_non_trivial <- npm_success_non_trivial %>% inner_join(min_oldenss_success_non_trivial) %>% inner_join(min_num_deps_success_non_trivial)

oldness_by_pkg_success_non_trivial <- oldness_by_pkg %>% inner_join(all_success_non_trivial)


## -----------------------------------------------------------------------------
better_oldness <- nrow(oldness_by_pkg_success_non_trivial  %>% filter(MinOldness < NPM)) /
  nrow(oldness_by_pkg_success_non_trivial)
worse_oldness <- nrow(oldness_by_pkg_success_non_trivial  %>% filter(MinOldness > NPM)) /
  nrow(oldness_by_pkg_success_non_trivial)
write(
  str_c("\\newcommand{\\dataFractionNewer}{", 
        round(better_oldness * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
better_oldness
write(
  str_c("\\newcommand{\\dataFractionOlder}{", 
        round(worse_oldness * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
worse_oldness


## -----------------------------------------------------------------------------
better_oldness_min_deps <- nrow(oldness_by_pkg_success_non_trivial  %>% filter(MinNumDeps < NPM)) /
  nrow(oldness_by_pkg_success_non_trivial)
worse_oldness_min_deps <- nrow(oldness_by_pkg_success_non_trivial  %>% filter(MinNumDeps > NPM)) /
  nrow(oldness_by_pkg_success_non_trivial)
write(
  str_c("\\newcommand{\\dataFractionNewerMinimizingNumDeps}{", 
        round(better_oldness_min_deps * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
better_oldness_min_deps
write(
  str_c("\\newcommand{\\dataFractionOlderMinimizingNumDeps}{", 
        round(worse_oldness_min_deps * 100),
        "\\%}\n"),
  results_tex, append=TRUE)
worse_oldness_min_deps


## -----------------------------------------------------------------------------
oldness_by_pkg_success_non_trivial %>%
  ggplot(aes(x=NPM,y=MinNumDeps)) + 
  geom_point(shape=4, size=1.5) + 
  geom_segment(aes(x = 0, y = 0, xend = 1, yend = 1), size=0.02, color="red") +
  xlab("Oldness with NPM") +
  ylab("Oldness when minimizing # dependencies") +
  mytheme()

mysave("oldness_scatterplot_minimzing_num_deps.pdf")


## -----------------------------------------------------------------------------
oldness_data %>%
  filter(!is.nan(Oldness)) %>%
  pivot_wider(names_from=Solver, values_from=Oldness) %>%
  select(!MinNumDeps) %>%
  mutate(Delta = NPM - MinOldness) %>%
  mutate(Ratio = MinOldness / NPM)
  # filter(Delta > 0)


## -----------------------------------------------------------------------------
oldness_data %>%
  filter(!is.nan(Oldness)) %>%
  pivot_wider(names_from=Solver, values_from=Oldness) %>%
  ggplot(aes(x=NPM,y=MinOldness)) + 
  geom_point(shape=4, size=1.5) + 
  geom_segment(aes(x = 0, y = 0, xend = 1, yend = 1), size=0.02, color="red") +
  xlab("Oldness with NPM") +
  ylab("Oldness when minimizing oldness") +
  mytheme()

mysave("oldness_scatterplot.pdf")



## -----------------------------------------------------------------------------
vanilla_sizes <- read_tsv(paste(sizes_root, "/vanilla.tsv", sep=""), col_names = c("Size", "Project"), show_col_types = FALSE) %>% drop_na()
min_deps_sizes <- read_tsv(paste(sizes_root, "/npm_min_num_deps.tsv", sep=""), col_names = c("Size", "Project"), show_col_types = FALSE) %>% drop_na()
min_oldness_sizes <- read_tsv(paste(sizes_root, "/npm_min_oldness.tsv", sep=""), col_names = c("Size", "Project"), show_col_types = FALSE) %>% drop_na()
min_duplicates_sizes <- read_tsv(paste(sizes_root, "/npm_min_duplicates.tsv", sep=""), col_names = c("Size", "Project"), show_col_types = FALSE) %>% drop_na()

ok_projects <- raw_data %>% 
  filter(Rosette == FALSE & Status == "success") %>% 
  select(Project) %>%
  inner_join(raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_num_deps,min_oldness") %>%
            select(Project)) %>%
  inner_join(raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_oldness,min_num_deps") %>%
            select(Project)) %>%
  inner_join(raw_data %>% 
            filter(Rosette == TRUE & Status == "success" & Consistency == "npm" & DisallowCycles == "allow_cycles" &
                   Minimize == "min_duplicates,min_oldness") %>%
            select(Project))

size_per_project_solver <- ok_projects %>% 
  inner_join(vanilla_sizes) %>% rename(NPM = Size) %>%
  inner_join(min_deps_sizes) %>% rename(MinDeps = Size) %>%
  inner_join(min_oldness_sizes) %>% rename(MinOldness = Size) %>%
  inner_join(min_duplicates_sizes) %>% rename(MinDuplicates = Size)

size_per_project_solver


## -----------------------------------------------------------------------------
size_shrinkage <- size_per_project_solver %>%
  mutate(ShrinkageMinDeps = MinDeps / NPM,
         ShrinkageMinOldness = MinOldness / NPM,
         ShrinkageMinDuplicates = MinDuplicates / NPM) 
           
mean(size_shrinkage$ShrinkageMinDeps)
mean(size_shrinkage$ShrinkageMinOldness)
mean(size_shrinkage$ShrinkageMinDuplicates)


## -----------------------------------------------------------------------------
min_dep_analysis_shrinkage %>% filter(Comparison == "NPM_NPM_MinDepsOldness_Shrinkage") %>% inner_join(size_shrinkage) %>% select(Project, Shrinkage, ShrinkageMinDeps) %>% rename(NumDepsShrink = Shrinkage, FSShrink = ShrinkageMinDeps)


## -----------------------------------------------------------------------------
size_shrinkage %>% 
  select(Project,ShrinkageMinDeps,ShrinkageMinOldness,ShrinkageMinDuplicates) %>%
  pivot_longer(cols = starts_with("Shrinkage"), names_to="Config", values_to="Shrinkage") %>%
  filter(Config=="ShrinkageMinDeps") %>%
  ggplot(aes(x=Shrinkage)) + stat_ecdf() + mytheme() + xlab("Fraction of size on disk") + ylab("Percentage of packages")

mysave("disk_shrinkage_ecdf.pdf")


## -----------------------------------------------------------------------------
fs_shrinkage <- size_shrinkage %>% 
  select(Project,ShrinkageMinDeps,ShrinkageMinOldness,ShrinkageMinDuplicates) %>%
  pivot_longer(cols = starts_with("Shrinkage"), names_to="Config", values_to="Shrinkage") %>%
  filter(Config=="ShrinkageMinDeps") %>% select(Shrinkage) %>% summarise(Mean = mean(Shrinkage), Median = median(Shrinkage), Quantile25 = quantile(Shrinkage, 0.25))

fs_shrinkage

write(
  str_c("\\newcommand{\\dataFSShrinkageMean}{", 
        round(fs_shrinkage$Mean, digits=2),
        "}\n"),
  results_tex, append=TRUE)

write(
  str_c("\\newcommand{\\dataFSShrinkageMedian}{", 
        round(fs_shrinkage$Median, digits=2),
        "}\n"),
  results_tex, append=TRUE)

write(
  str_c("\\newcommand{\\dataFSShrinkageQuartileFirst}{", 
        round(100 * fs_shrinkage$Quantile25, digits=2),
        "}\n"),
  results_tex, append=TRUE)



## -----------------------------------------------------------------------------
# size_shrinkage %>% 
#   select(Project,ShrinkageMinDeps,ShrinkageMinOldness,ShrinkageMinDuplicates) %>%
#   pivot_longer(cols = starts_with("Shrinkage"), names_to="Config", values_to="Shrinkage") %>%
#   filter(Config=="ShrinkageMinDeps") %>%
#   ggplot(aes(x=Shrinkage)) + stat_ecdf() + mytheme() + xlim(0, 1.2)
# 
# mysave("disk_shrinkage_no_outliers_ecdf.pdf")


## -----------------------------------------------------------------------------
slowdowns <- read_csv(paste(perf_root,"/vanilla-perf.csv",sep=""),
         col_names = c("Project", "Time"),
         col_types = cols(Project = col_factor(), Time = col_double()),
         show_col_types = FALSE) %>%
  group_by(Project) %>%
  summarise(NPM = mean(Time)) %>%
  ungroup() %>%
  inner_join(
    read_csv(paste(perf_root,"/rosette-perf.csv",sep=""),
             col_names = c("Project", "Time"),
             col_types = cols(Project = col_factor(), Time = col_double()),
             show_col_types = FALSE) %>%
        group_by(Project) %>%
      summarise(MinNPM = mean(Time)) %>%
      ungroup()) %>%
  mutate(Slowdown = MinNPM - NPM) %>%
  select(Project, Slowdown)


## -----------------------------------------------------------------------------
new_slows <- slowdowns %>% filter(Slowdown > 15)
new_slows


## -----------------------------------------------------------------------------
slowdowns %>% ggplot(aes(x=Slowdown)) + 
  stat_ecdf() +
  xlab("Additional time taken with MinNPM (s)") +
  ylab("Percentage of packages") +
  mytheme()

mysave("slowdown_ecdf.pdf")


## -----------------------------------------------------------------------------
slowdowns %>% ggplot(aes(x=Slowdown)) + 
  stat_ecdf() +
  xlab("Additional time taken with MinNPM (s)") +
  ylab("Percentage of packages") +
  mytheme() + xlim(0, 20)

mysave("slowdown_ecdf_no_outliers.pdf")


## -----------------------------------------------------------------------------
mean_slowdown <- round(mean(na.omit(slowdowns$Slowdown)), digits = 1)
median_slowdown <- round(median(na.omit(slowdowns$Slowdown)), digits = 1)
max_slowdown <- round(max(na.omit(slowdowns$Slowdown)), digits = 1)

write(
  str_c("\\newcommand{\\dataMeanSlowdown}{", 
        mean_slowdown,
        "s}\n"),
  results_tex, append=TRUE)
write(
  str_c("\\newcommand{\\dataMedianSlowdown}{", 
        median_slowdown,
        "s}\n"),
  results_tex, append=TRUE)
write(
  str_c("\\newcommand{\\dataMaxSlowdown}{", 
        max_slowdown,
        "s}\n"),
  results_tex, append=TRUE)

mean_slowdown
median_slowdown
max_slowdown

