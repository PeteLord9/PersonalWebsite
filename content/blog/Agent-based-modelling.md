+++
title = 'What is Agent-Based Modelling?'
date = 2026-09-25
draft = false
description = "An introduction to agent-based modelling, complex systems and its applications in public health."
tags = [ "abm", "complexsystems", "publichealth"]
+++

<!--
formatting note: 
+++ (three plus signs) tells Hugo to expect TOML (uses = for values).
--- (three dashes) tells Hugo to expect YAML (uses : for values).
-->

This is my first real blog post. Obviously it had to be on the topic of agent-based modelling (ABM). 

So what is ABM? In short, it is a simulation method that models the behaviours and decisions of autonomous agents in a system and how they interact with each other and their environment (Brennan et al., 2006). The process of modelling allows the macro level outcomes of the system to emerge from the micro level behaviours of the individuals (Badham et al., 2018). These so  called 'agents' can be any sensing, decision-making entity; from trees to governments to drones, but in the sphere of public heath, it tends to be representative of people. In public health and health economics, ABM is a unique tool. Unlike statistical models, ABM allows us to model the mechanisms of disease. That is to say ABMs can model not just *what* happens but *how* it happens. This is important because it gives an understanding of the underlying mechanisms.

ABMs can capture dynamic effects, physical and social interactions, environments, feedback loops, non-linear dynamics and heterogeneity in a way that other methods cannot. ABM is therefore a great method for simulating complex systems, of which these are all hallmarks (Breeze et al., 2023). In modelling social systems (i.e. systems made up of people), ABM can constrain predictions using both empirical evidence and social theory. This is important because it allows us to model the system in a way that is grounded in reality, rather than just being just a statistical model or theoretical model that may not reflect the real world. Although the predictive power and policy usefulness of ABM is an open question, ABMs can produce "justified stories" (Badham et al., 2021) about what is possible in a system where simplifying to a single outcome is reductionist and omits inherent uncertainty in explaining the past or predicting the future.

From the perspective of a public health professional, ABM is a great tool for understanding the system of disease and the impact of interventions, particularly where human behaviour is involved. Better policy can come from a better understanding of the system, knowing how actors might adapt to interventions, or finding hidden drivers of unequal health outcomes. Unlike an opaque statistical model, ABM can speak to non-modellers to show how human behaviour under what seems like a reasonable decision under different circumstances can lead to unexpected or undesirable outcomes. For example, ABM has been used to model the spread of infectious disease to explain how information spread affects vaccination programmes that subsequently change the dynamics of disease transmission, or to model smoking cessation  under different policy scenarios to understand how the system might adapt to interventions.

From the perspective of a health economist, ABM is an interesting tool for predicting the long term outcomes of interventions. For example, its pretty well understood that alleviating poverty in childhood would be much more cost effective than alleviating some chronic disease in old age. However, do you actually show how much more cost effective it is? Building an ABM might give a more accurate picture of the long term impact of a complex intervention such as a poverty alleviation program like the 2-child benefit cap by using behavioural theory to explain what changes in behaviour might occur as a result of the intervention, and how these changes might impact the system over time. 

At Sheffield University, the current work we are doing is building an ABM of smoking cessation under the COM-B theory of behaviour change (Tian et al., 2024). This is an exciting time for smoking policy, the UK government is implementing the Smokefree Generation policy (Cancer Research UK 2026) and vaping is taking over as the most prevalent form of nicotine consumption. We are using ABM to understand how these changes in the system might impact smoking cessation and the health inequalities that arise from it.

There is a lot more to say about ABM, but I will leave it there for now...

## References

Brennan, A., Chick, S. E., & Davies, R. (2006). A taxonomy of model structures for economic evaluation of health technologies. Health Economics, 15(12), 1295–1310. https://doi.org/10.1002/hec.1148

Badham, J., Chattoe-Brown, E., Gilbert, N., Chalabi, Z., Kee, F., & Hunter, R. F. (2018). Developing agent-based models of complex health behaviour. Health & Place, 54, 170–177. https://doi.org/10.1016/j.healthplace.2018.08.022

Breeze, P. R., Squires, H., Ennis, K., Meier, P., Hayes, K., Lomax, N., Shiell, A., Kee, F., de Vocht, F., O’Flaherty, M., Gilbert, N., Purshouse, R., Robinson, S., Dodd, P. J., Strong, M., Paisley, S., Smith, R., Briggs, A., Shahab, L., … Brennan, A. (2023). Guidance on the use of complex systems models for economic evaluations of public health interventions. Health Economics, 32(7), 1603–1625. https://doi.org/10.1002/hec.4681

Badham, J., Barbrook-Johnson, P., Caiado, C., & Castellani, B. (2021). Justified Stories with Agent-Based Modelling for Local COVID-19 Planning. Journal of Artificial Societies and Social Simulation, 24(1), 8.

Tian, D., Squires, H. Y., Buckley, C., Gillespie, D., Tattan-Birch, H., Shahab, L., West, R., Brennan, A., Brown, J., & Purshouse, R. C. (2024). Incorporating the COM-B Model for Behavior Change into an Agent-Based Model of Smoking Behaviors: An Object-Oriented Design. 2024 Winter Simulation Conference (WSC), 252–263. https://doi.org/10.1109/WSC63780.2024.10838986

Creating a smokefree generation | Cancer Research UK. (2026). Retrieved 25 September 2026, from https://www.cancerresearchuk.org/get-involved/campaign-with-us/all-our-campaigns/smokefreeuk/creating-a-smokefree-generation
