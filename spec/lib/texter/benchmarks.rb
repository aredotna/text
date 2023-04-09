# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.describe Texter::Content do
  let(:contents) do
    [
      'Technical roadmap: OpenSearch extensibility

      Wed, Apr 05, 2023 · Daniel (dB.) Doubrovkine
      The primary reason users choose OpenSearch is the wide range of use cases they can address with its features, such as search or log analytics. Thus, we aim to make the OpenSearch Project the preferred platform for builders by creating a vibrant and deeply integrated ecosystem of projects, features, content packs, integrations, and tools that can be found quickly, installed securely, combined to solve problems, and monetized by many participants.

      The existing mechanism used to extend OpenSearch and OpenSearch Dashboards is a plugin framework. It provides a useful way to extend functionality, particularly when the new functionality needs access to a significant number of internal APIs. However, the plugin framework presents a number of challenges for users and developers in the areas of administration, dependency management, security, availability, scalability, and developer velocity. To begin solving these, we’ve embarked on a journey to replace the OpenSearch plugin mechanism with a new catalog of extensions. We plan to ship two new SDKs for OpenSearch and OpenSearch Dashboards and then launch a catalog of extensions.

      In this blog post, we’ll introduce the concept of extensions and outline some proposed projects in this area.

      Introducing extensions

      From the product point of view, extensions are a new mechanism that provides a way to break up a monolithic, tightly coupled model for building new features in OpenSearch. Technically, extensions are a simple evolution of plugins—or plugins decoupled from their OpenSearch/Dashboards hosts. In practice, an extension is only different from a plugin in that it only depends on the OpenSearch/Dashboards SDK and works with multiple versions of OpenSearch/Dashboards. We aim for the existence of many more extensions than there are plugins today, written by many more developers. Then we will sunset plugins.

      We want for extensions to become the preferred mechanism for providing functionality in OpenSearch/Dashboards. Having multiple competing implementations will produce extensions with high performance, improved security, and versatile features for all categories of users, administrators, and developers.

      Extensions roadmap

      The following proposed projects are in chronological order, but many of them can be accomplished in parallel.

      Provide experimental SDKs and move extensibility concerns out of the cores

      First, we plan to introduce an OpenSearch SDK and an OpenSearch Dashboards SDK and refactor the OpenSearch/Dashboards cores to support them as needed. This creates both a logical and a physical separation between extensions and their hosts. You should be able to author an extension that is compatible with all minor versions of an OpenSearch/Dashboards release and to upgrade OpenSearch/Dashboards without having to upgrade an installed extension.

      The SDK assumes current and future extensibility concerns from OpenSearch/Dashboards. It will contain the set of APIs that need to follow semver, significantly reducing the number of APIs that OpenSearch/Dashboards needs to worry about, because plugins only take a dependency on the SDK. With a semver-stable SDK, plugins can confidently declare that they work with, for example, OpenSearch/Dashboards >= 2.3.0 (2.3, 2.4, … 3.0, and so on) or ~> 2.5 (any 2.x after 2.5). The SDK will provide support for integration testing against broad ranges of OpenSearch/Dashboards versions. It can begin selecting common functionality that all plugins may need, such as storing credentials or saving objects, and be strongly opinionated about what constitutes a semver-compatible extension point for OpenSearch/Dashboards. Instead of importing a transitive dependency (for example, oui), developers import an SDK namespace (for example, sdk/ui).

      The SDK will be much smaller in size than OpenSearch/Dashboards. To develop an extension on top of an SDK, you will not need to check out and build OpenSearch/Dashboards. We will publish the SDKs to maven/npm; they will follow their own semver and will have documentation of public interfaces. The SDK can also choose to implement wrappers for multiple major versions of OpenSearch/Dashboards, extending compatibility much further and enabling developers to write extensions once for several major versions of OpenSearch. Finally, extension testing can be performed against a released, downloaded, and stable version of OpenSearch/Dashboards.

      This project is currently in progress. The SDK for OpenSearch exists, the SDK repo for OpenSearch Dashboards has been created, and some POCs for plugins as extensions exist. See OpenSearch #2447, opensearch-sdk-java #139, OpenSearch-Dashboards #2608, and OpenSearch-Dashboards #3095.

      Add security support for extensions in the OpenSearch/Dashboards cores

      In the plugin model, security is also a plugin. This means security can be optional, which makes it difficult for plugins to build features such as field- and document-level security (FLS/DLS), which perform data access securely. Each plugin must implement data access checks independently and correctly, which has proven to be difficult (see security #1895 for some examples). A simpler and more secure implementation would make all operations inside OpenSearch permissible, no matter the source, syncing access checks to the lower levels. The SDKs move extensibility concerns out of the cores. They will have brand-new APIs, presenting the most opportune time to require a security context in all OpenSearch API calls. It should, of course, still be possible to disable security as needed.

      We plan to add authentication mechanisms to the OpenSearch core (every API call or new thread/process will carry an identity) and perform authorization when accessing data at the level of these APIs in a way that is backward compatible with the Security plugin. Authorization checks will be enabled using the Security plugin for core APIs exposed in the SDK, and there will be no changes required in plugins to ensure backward compatibility.

      We currently have an active feature branch for adding security support for extensions in OpenSearch. See OpenSearch #5834.

      Replace plugins in the OpenSearch/Dashboards distribution

      One of the main reasons for the existence of the default OpenSearch distribution is that it provides a set of secure, signed binaries along with a rich set of features (plugins). We have invested in a large automation effort in the open-source distribution to make this process safe and repeatable. However, producing this distribution still requires significant logistical and technical coordination, plus the semi-automated labor of incrementing versions, adding components to manifests, and tracking unstable upstreams. The toughest challenge to overcome is developers having to develop, build, and test plugins against moving targets of non-stable versions of the OpenSearch/Dashboards cores.

      We aim for extensions to ship independently, either more or less often than the official distribution. Users should be able to upgrade OpenSearch clusters much more easily because they won’t need to upgrade installed extensions. Additionally, with fewer versions of released extensions containing no new features, there will be less security patching.

      For each existing plugin that ships with the OpenSearch distribution, we will need to design a technical path forward, but this phase will present no change in user experience for the default OpenSearch/Dashboards distribution. First, we will design and implement interfaces that need to be exported via the OpenSearch/Dashboards SDK. This presents an opportunity to redesign extension points to be simpler and more coherent and an opportunity to refactor classes in OpenSearch/Dashboards. Plugins remove the dependency on OpenSearch/Dashboards and add a dependency on the SDK, reimplement the calls, and are then available as extensions. Second, to migrate the entire Security plugin into the core, we will need to add support for authorization in REST handlers, implement authorized request forwarding in the REST layer, add support for asynchronous operations and background tasks, and add system index support to allow extensions to reserve system indexes. Finally, the distribution mechanisms can begin picking up the latest available version of an extension, and releasing those artifacts as a bundle instead of rebuilding everything.

      OpenSearch Dashboards cohesion through interfaces

      OpenSearch Dashboards is a single product that includes the core platform (for example, the application chrome, data, and saved objects APIs), native plugins (for example, Home, Discover, Dev Tools, and Stack Management), and feature plugins (for example, Observability, Anomaly Detection, Maps, and Alerting).

      The current Dashboards experience is not cohesive. As you move between core experiences and feature plugins, there are visual inconsistencies in the fonts, colors, layouts, and charts. Feature plugins are mostly siloed experiences and don’t render on dashboard pages. Feature plugins are built differently than the native plugins. For example, they often don’t leverage existing interfaces, such as saved objects, to store UI-configured metadata, or render embedded components on dashboard pages. Additionally, Dashboards currently uses six libraries for rendering visualizations and offers six visualization authoring experiences with overlapping functionality, each with its own implementation.

      Consolidating UI component and visualization rendering libraries into an SDK will reduce maintenance and cognitive burden. We’ll introduce a configuration and template system and a style integrator so that common default preferences can be set once instead of on every visualization. We’ll standardize and modularize configuration options so that UI components are consistent and saved visualizations are cross-compatible. We’ll clearly separate data source configurations and fetching from visualization configurations. We’ll define capabilities and behavior that visualizations should satisfy so that it’s quicker and easier to build new visualization type definitions that are still fully featured.

      For more information, see OpenSearch-Dashboards #2840 and OpenSearch-Dashboards #2880.

      In-proc support for OpenSearch extensions

      We designed extensions to have a clear API boundary, yet lost the ability to host extensions on the same JVM, adding about 10% serialization overhead to the process. We want to give extension developers the ability to remove that overhead, at the same time providing cluster administrators with more control and improving safety and security.

      A number of extensions, such as language analyzers or storage extensions, live on the critical path of high throughput and may not be able to achieve high performance due to the overhead of additional inter-process communication. Furthermore, for any non-trivial number of extensions (about 10 or more), these extensions will be unlikely to run effectively in separate JVM or Node.js processes without negatively impacting nodes. To satisfy high performance requirements, we will need to reintroduce a way for extensions to run on the same JVM as OpenSearch or to share Node.js processes for OpenSearch Dashboards while giving administrators a way to gain performance in exchange for security isolation, support for extensions written in multiple languages, and multiple major version compatibility.

      Practically speaking, we will need to provide the ability for a subset of OpenSearch extensions to run on the same JVM, and operate on data structures without serialization or deserialization, all without the need to change anything in the implementation of the extension itself.

      Support dependencies between extensions

      In the current state, all dependencies are implicit, and all versions across cores and plugins must match. Therefore, we heavily rely on testing a distribution bundle. There’s no mechanism for knowing what the dependencies are, and all dependency errors are found at runtime. Any update to the dependencies requires rebuilding other plugins, even when there are no changes within the current plugin. Thus, everything is always rebuilt from scratch for every release. To solve this problem, we will add the ability for extensions to depend on other extensions, similar to the ability of an extension to depend on a semver-compatible version of OpenSearch/Dashboards.

      Public catalog

      We’ll augment the previously built rudimentary schema for an extension’s metadata to provide additional fields beyond name, version, and compatibility. These will include such fields as well-defined categories and additional vendor/sponsor information. We will build a minimal catalog website with search functionality and deploy and maintain a public version of it. We’ll ensure that the catalog system can also be run by any enterprise internally, building signing and trust into the system, but will not perform any validation beyond metadata correctness at this stage. An internal catalog will be able to sync with a public catalog with appropriate administrative controls. Alternatively, existing third-party catalog systems will use an API to import extensions. Developers will be able to sign up to publish extensions on the public instance, and we will build mechanisms that help users trust publishers. An API in OpenSearch will support installing extensions from catalogs. A view in OpenSearch Dashboards will allow browsing of available catalogs and extensions.

      Developers will be able to publish extensions to a public catalog; users will be able to find extensions in this catalog with a taxonomy and search functions. We’ll provide detail pages with meaningful metadata and vendor information, and administrators will be able to install extensions from public or private catalogs and import a subset of a public catalog into their enterprise. Finally, we’ll add a way for publishers to verify themselves, add quality controls, and possibly include publisher approvals.

      Supporting extensions in OpenSearch high-level language clients

      We are in the process of improving support for existing plugins in clients by publishing REST interfaces in the form of OpenAPI specs. A generator will consume the spec and output parts of a complete high-level thin client for the OpenSearch distribution.

      We will similarly support extensions in the clients by creating thin clients for each extension that will be composable with the core client in every supported programming language. Extensions will publish REST interfaces in the form of OpenAPI specs, and a generator will consume the spec and output a complete high-level thin client. The burden of m * n extensions and languages will be alleviated by automating as much of the process as possible, and providing build and test tooling such as CI workflows, so that both project-owned extensions and third-party-developed extensions benefit from uniform support. The extension owner can then take the generated clients and publish them to their package repositories of choice. The core clients will define stable low-level/raw interfaces with their transport layer such that the thin clients compose as expected and follow semver compatibility rules.

      See opensearch-clients #19 for more information.

      Rewrite most plugins as extensions

      We will provide a way to deprecate plugins by implementing all corresponding plugin features in extensions, with the goal of minimizing the effort required to migrate. We will write a migration guide that clearly specifies the effort required to perform the initial migration and follow-up deprecated feature replacement so that you can integrate it into your own task planning, offer code that makes the migration from plugins to extensions easier, implement samples that provide one-to-one analogs with the existing plugin framework, and create assurances that external behavior in the migration has not changed. Code permitting this quick bridge may be marked deprecated but will allow you to methodically remove the deprecated code over time.

      For more information, see opensearch-sdk-java #315.

      Deprecate plugins and unbundle distributions

      Assuming extensions have been widely adopted, we can deprecate the plugin APIs and remove them from the next major version of OpenSearch. We don’t expect this to happen earlier than OpenSearch 4.0. Older plugin versions will continue to work with older versions of OpenSearch and receive security patches.

      We will replace the two distribution flavors of OpenSearch/Dashboards (currently a -min distribution without security or plugins) with a set of distribution manifests tailored for such purposes as log analytics and search. Each distribution will be represented by a manifest that can be assembled by downloading the artifacts from the public catalog for packaging purposes. We want to enable single-click installation of a collection of extensions, provide recommended distributions of OpenSearch for tailored purposes, let vendors create their favorite flavor of OpenSearch/Dashboards distribution easily, and add the capability to create enterprise-tailored distributions.

      Future

      Extensions will make a lot of new, big ideas possible! Here are some of our favorites.

      Hot swap extensions

      OpenSearch/Dashboards bootstrap plugins at start time, and various parts of the system assume that plugins do not change at runtime. Requiring a cluster restart for all extensions is a severely crippling limitation on the path of ecosystem adoption of any significant number of extensions, primarily because cluster restarts mean stopping inbound traffic. We will ensure that any extension point can be loaded or unloaded at runtime by making settings in the OpenSearch core dynamic and adding tools to support loading and unloading extensions at runtime without restarting OpenSearch/Dashboards nodes or the entire cluster. This creates the ability to add, upgrade, or remove an extension without the need to restart OpenSearch/Dashboards or connect a remote extension to an existing OpenSearch/Dashboards cluster.

      Extensible document parsing

      JSON is, by far, the most popular input format for OpenSearch. JSON is humanly readable, so it is fairly easy to test and use for development. Additionally, the OpenSearch ecosystem is built around JSON, with most benchmarks written in JSON and ingest connectors supporting JSON. However, JSON is much slower and more space-consuming than most binary formats, thus swapping JSON for another type may yield significant performance gains. We would like to make OpenSearch input formats extensible so that it is easier to add and test more formats. This was proposed in OpenSearch #4559.

      Security isolation

      With extensions being designed to run on a separate virtual machine (VM), we can introduce multiple options for isolating extensions, such as containers and Java runtimes (for example, Firecracker, GraalVM, and EBPF). We can also provide a new secure default runtime and solve the problem of Java Security Manager (JSM) deprecation. We can further extend security across new boundaries, ensuring all messages are encrypted in transit and all data is encrypted at rest.

      Search processors become extensions

      In search-processor #80, we proposed a new search processor pipeline. Search processors are plugins that can become extensions before plugins are deprecated.

      Storage plugins become extensions

      The storage API in OpenSearch has proven to be quite stable. There may be no need to change storage extensions across OpenSearch versions. New features and improvements in the respective remote storage clients (for example, Microsoft Azure or Amazon Simple Storage Service (Amazon S3)) happen separately from OpenSearch distributions, so these extensions can be upgraded and improved without needing to wait for a new OpenSearch release. We also want partners to maintain their own storage, removing the idea of “first-class storage.”

      With the addition of features like remote-backed indexes and searchable snapshots, the storage plugins (for example, Amazon S3, Azure, GCP, and HDFS) are on the critical path for both indexing and search operations. These plugins will not be able to ship with any performance penalty because it is likely to make for an unacceptable user experience. We’ll use the in-process support for extensions to move these plugins to the extensions model. We could abstract just reading or writing, support multiple versions of Lucene side by side, or use different storage engines and initialize one engine per index.

      Replication as an extension

      With the introduction of segment replication (segrep), node resources need to be allocated to perform file copy. Today there are settings that define limits on data transfer rates (for segrep and recovery) to prevent these functions from consuming valuable resources required for indexing and search. Moving this functionality to a separate node-local JVM allows us to control maximum resource consumption (CPU/memory) and avoid unnecessary throttling and any impact on read and write performance. We can therefore define new extension points on the engine to support segrep implementations that can run as a sidecar and provide the opportunity to plug in an implementation based on storage requirement (remote, node-node). This will be either in process or in a separate node-local process and will be integrated with the storage plugins to support remote store as a replication source.

      Extensions in other programming languages

      With extensions designed to operate remotely, we can support out-of-process extensions written in other languages running on the JVM and remote extensions written in any other language hosted externally. By enabling polyglot applications or porting the extension SDKs to other programming languages, we will also lower the barrier to entry for authoring extensions in languages such as Ruby with a JRuby SDK or add support for in-proc extensions written in TypeScript running on GraalVM.

      Extensions in other technologies

      An extension cannot be entirely implemented in an Azure Function or AWS Lambda because it must maintain a network connection with OpenSearch and share some state information. It is possible to create a client for this purpose with an internal Lambda implementation to enable Lambda extensions.

      Aggregations as an extension

      As we work toward separating search aggregations and compute, we will refactor and extract interface and SDK components for compute separately from the search phase lifecycle. Simple search aggregations, which default to the current single-pass data aggregation implementation, may still be supported for basic search use cases. Separating the compute framework through extensions and a developer SDK enables drop-in replacements from more evolved data analytics systems, such as Spark. By separating the search aggregation framework through extensions and a developer SDK, third-party contributors can leverage new kinds of search aggregation support, such as principal component analysis (PCA) or stratified sampling pipeline aggregations.

      Cluster manager as an extension

      We would like to refactor and extract cluster management interfaces to remove the existing cluster manager node limit of ~200. For large deployments, we believe we can provide alternate cluster manager implementations that have a different scalability and availability model.

      Offloading background tasks to extensions

      A number of background operations currently run asynchronously in an OpenSearch cluster, including Lucene segment merges, data tier migrations (for example, hot to warm to cold), and most operations performed by Index State Management (ISM). These can be offloaded to dedicated or isolated compute instances through the extensions mechanism, improving cluster scalability and availability.

      Communication protocols as extensions

      By making communication protocols extensible, we can experiment with more performant implementations such as GRPC or no- or low-garbage-collection implementations (for example, Netty) without having to modify the core engine. Check out opensearch-sdk-java #414, which prototypes protobuf serialization.

      Help wanted

      This blog post reflects some of our current project plans. Like all plans, they may change as we make progress, and we would love your help! The best way to start is by checking out opensearch-sdk-java. Try to implement a trivial extension on top of it, or help us port an existing plugin. You could also pick up one of the issues labeled “good first issue” in that project or start with one of the ideas we mentioned above. As always, please let us know how we can help by opening new issues or posting to the forums.',
      '我曾指出，海德格尔的Sein und Zeit应该翻译为《是与时(间)》，因为其中的核心概念Sein应该翻译为“是”，而不应该翻译为“存在”。[1]、[2]、[3]
      与此相关的问题，从小处思考，乃是如何理解海德格尔哲学的问题；从大处着眼，则是应该如何理解西方哲学的问题。[2]、[4]
      在我看来，把Sein翻译为“存在”，是无法理解海德格尔的。本文将以中译本《存在与时间》[5]
      导论中的一段重要论述为例，具体地说明这个问题。首先我要说明，关于“存在”的论述有许多无法理解之处，然后我把“存在”修正为“是”，依据这样的阅读来理解，海德格尔说的究竟是什么，最后我再谈一谈自己的认识

      一、“存在”与发问的结构

      《存在与时间》导论的题目是“概述存在意义的问题”，共两章。第一章是“存在问题的必要性、结构和优先地位”，其中第二小节为“存在问题的形式结构”。 显然，这一小节的内容与该章题目中所说的“结构”相对应。此外，仅从字面上看，似乎“必要性”和“优先地位”是比较虚的东西，而“结构”是比较实的东西，因此第二小节的内容对于我们理解存在的意义似乎会更直接更具体一些，由此也表明，它的内容对于我们理解存在的意义是至关重要的

      第二小节说的是关于存在的发问的形式结构，大致分为三部分。第一部分谈论一般的发问结构；第二部分提出了关于存在的发问的形式，第三部分对照一般发问的结构，围绕存在发问的形式展开关于它的发问结构的论述。限于篇幅，我们仅集中讨论前两部分。

      [译文1]存在的意义问题还有待提出。如果这个问题是一个基本问题或者说唯有它才是基本问题，那么就必须对这一问题的发问本身做一番适当的透视。所以，我们必须简短地讨论一下任何问题都一般地包含着的东西，以便能使存在问题作为一个与众不同的问题映入眼帘。

      任何发问都是一种寻求。任何寻求都有从它所寻求的东西方面而来的事先引导。发问是在“其存在与如是而存在”[Das-und Sosein]的方面来认识存在者的寻求。这种认识的寻求可以成为一种“探索”，亦即对问题所问的东西加以分析规定的“探索”。发问作为“对……”的发问而具有问之所问[Gefragtes]。一切“对……”的发问都以某种方式是“就……”的发问。发问不仅包含有问题之所问，而且也包含有被问及的东西[Befragtes]。在探索性的问题亦即在理论问题中，问题之所问应该得到规定而成为概念。此外，在问题之所问中还有问之何所以问[Erfragtes]，这是真正的意图所在，发问到这里达到了目标。既然发问本身是某种存在者即发问者的行为，所以发问本身就具有存在的某种本己的特征。发问既可以是“问问而已”，也可以是明确地提出问题。后者的特点在于：只有当问题的上述各构成环节都已经透彻之后，发问本身才透彻。

      存在的意义问题还有待提出的。所以，我们就必须着眼于上述诸构成环节来讨论存在问题。[5](P6～7)

      这段译文是第二节的开场白，共含三小段。第一小段有一点值得重视，这就是其中所说的“任何问题都一般地包含着的东西”。这一点说明，存在的意义问题乃是具有普遍性的问题。不过，由于没有展开论述，我们也就暂且不予过多地讨论。第三小段说明以后该如何讨论，没有什么具体的意义。因此我们集中讨论其中第二小段，这也是这段话的重点。

      第二小段认为，发问是一种寻求，而寻求可以成为一种探索。在这样的前提下，该段探讨了发问的构成环节。发问是一种认识性的寻求，因此有发问的对象、发问的方式、发问所涉及的东西、发问的原因；此外，还有不同的发问种类等等。搞清楚这些，才能搞清楚发问。若是不深究，这些意思大体上还是可以理解的。但是，如果仔细分析，就有一些无法理解的问题。

      一个问题与关于发问的一般说明有关，即“发问是在‘其存在与如是而存在’[Das-und Sosein]的方面来认识存在者的寻求”。这是关于发问是一种寻求的说明。由此似乎可以看出，这样一种寻求旨在认识存在者。问题在于关于这种认识的两个方面的说明。一个方面是“其存在”，这大概是指存在者的存在。我不知道，认识存在者的存在，或者从存在者的存在来认识存在者，这样的论述是不是可以理解，但是我想问，这样的论述是什么意思？其意义是什么？尤其是，这里是在论述发问，因此我们应该结合发问来理解这里的论述。比如人们问：“人是什么？”在这个问题中，什么是存在者，什么是存在呢？我理解不了在这里会有存在者和存在之分，也理解不了在这里什么是存在者，什么是存在。因此我要问，如何从存在者的存在来认识存在者呢？

      另一个方面是“如是而存在”。除了关于存在者的问题外，我同样无法理解，什么叫“如是而存在”？怎样才能“如是而存在”？还是以上面的这个问题为例。问“人是什么？”当然是在寻求得到关于“人是如此这般”的认识。问题是这里与存在有什么关系呢？而且，即使有关系，这样的问题难道是在寻求关于人的存在的认识吗？在我看来，关于“是怎样”的发问一定旨在得到“是如此这般”的回答，与存在没有什么关系；而“是如此这般”的表述也与存在没有什么关系。特别是，海德格尔这里说的是“任何发问”，他一定是在一般意义上谈论发问。无论如何，“什么存在？”或“存在什么？”也不会是具有普遍性的发问。因此我们无法理解，发问为什么会与存在相关呢？而且，发问为什么会与存在者的存在和存在者如是而存在有关呢？

      另一个问题与关于发问的具体说明有关。让我们先看下面这句话：“一切‘对……’的发问都以某种方式是‘就……’的发问”。“‘对……’的发问”与“‘就……’的发问”有什么区别吗？前者无疑是指问的对象，那么后者指什么呢？是指发问所着眼的东西吗？若是这样，“某物存在吗？”无疑是对“存在”的发问，但是，它是“就”什么而发问的呢？此外，由于这里说到“以某种方式”，因而可以看出，“就”什么而发问不是指发问的方式。那么这种方式指什么呢？与问的对象、问的方式不同的东西又会指什么呢？

      再看另一句话：“在问题之所问中还有问之何所以问[Erfragtes]”。这个“何所以问”是指什么呢？是指问题的原因，即为什么问吗？我想不明白。而且，为什么在这里达到了问题的目标呢？比如我们问“人是什么？”在这样一个问题中，什么是它的“何所以问”呢？或者，在“某物存在吗？”这样的问题中，什么是它的何所以问呢？

      这两句话是关于发问的具体说明，若是与前面的一般说明结合起来，则还会有更多无法理解的问题。比如，当我们问“某物存在吗？”的时候，显然是着眼于存在物的存在方面而发问，这时我们该如何区别“‘对……’的发问”和“‘就……’的发问”呢？我们又该如何认识这里的发问方式呢？而当我们问“人是什么？”的时候，除了上述这些要区别的问题外，我们又该如何与存在联系起来呢？换句话说，这怎么会是从“如是而存在”的角度来寻求对存在者的认识呢？

      如果再仔细分析，这里还有一个更深层次的问题。这里谈到“如是而存在”。从字面上看，这似乎是用“是”来解释“存在”，因为“存在”要“如是”。在这种情况下，这里是不是意味着“是”乃是比“存在”更为基础的概念呢？若是这样，“存在”又如何能够是最普遍的概念呢？

      由于有以上问题，“既然发问本身是某种存在者即发问者的行为，所以发问本身就具有存在的某种本己的特征”这句话也就有了无法理解的问题。其中的前半句可以理解，发问有发问者，因而发问是发问者的一种行为。把发问者看作存在者，当然也可以理解。问题是，由此如何可以得出发问本身具有存在的特征呢？以上面的例子为例，比如问“某物存在吗？”这个问句中含有“存在”，因而似乎可以说明这个询问具有存在的特征。但是，这样的问题并不具有普遍性，因而不能说明发问的特征。若是问“人是什么？”这样的发问倒是有普遍性了，但是它不含有“存在”，因而与存在并没有什么关系。那么它如何具有“存在”的特征呢？难道是因为可以有发问吗？

      以上是海德格尔关于发问的构成环节的讨论，下面我们看一看他关于“存在”的发问形式的讨论。

      [译文2]作为一种寻求，发问需要一种来自它所寻求的东西方面的事先引导。所以，存在的意义已经以某种方式可供我们利用。我们曾提示过：我们总已经活动在对存在的某种领会中了。明确提问存在的意义、意求获得存在的概念，这些都是从对存在的某种领会中生发出来的。我们不知道“存在”说的是什么，然而，当我们问道“‘存在’是什么？”时，我们已经栖身在对“是”[“在”]的某种领会之中了，尽管我们还不能从概念上明确这个“是”意味着什么。我们从来不知道该从哪一视野出发来把握和确定存在的意义。但这种平均的含混的存在之领会是个事实。[5](P7)(重点符号为引者所加)

      这段话明确探讨了存在的意义。前面说过发问是与存在相关的寻求，这里要探讨存在的意义，实际上是对存在的意义进行发问，因此这里的探讨也会与存在相关。由于人们总是活动在对存在的某种领会之中，因此，当人们探询存在的意义时，就已经有了对存在的某种领会。这样也就导致一个问题：应该如何把握存在的意义？海德格尔的这些意思大致是可以理解的。但是如果我们仔细分析，却有一些根本无法理解的问题。其中最主要的问题就在被我加上重点符号的这段话。

      从字面上看，问“‘存在’是什么？”依赖于对“是”的领会，乃是可以理解的，因为这个问句中的动词乃是“是”，用海德格尔的话说，这个问句用到了“是”这个词。当然，认为这样表达的时候我们并不明确知道这个“是”乃是什么意思，也是可以理解的。因为它只是一个系词，起语法作用，或者说，它的意思只是通过这种语法作用体现的。但是，海德格尔为什么不直接说“是”，而要在“是”的后面加上“[在]”呢？本来很明白的事情，加了这个“在”，反而让人不明白了。

      首先，为什么要在“是”后面加这个“在”呢？人们一般认为，西方语言中being一词是多义的，有“存在”、“在”、“有”和“是”等含义。大概是由于这个原因，就有了“是[在]”这样的译文。与此相类似，在其他地方也有“存在[是]”这样的译文。关于这个问题，我不想展开讨论，只想指出几个问题：一直在讨论“存在”，怎么忽然讨论起“是[在]”来了呢？“是[在]”和“存在”的意思是一样的吗？与此相关，“是[在]”和“存在[是]”的意思是一样的吗？“在”和“存在”的意思是一样的吗？怎么可以一会儿说“存在”，一会儿说“存在[是]”，一会儿说“是[在]”，一会儿又说“是”呢？也就是说，所要讨论的如此重要的一个概念，怎么能够随意变来变去呢？

      其次，“‘存在’是什么？”这个问题是非常明确的。说这个问题依赖于对“是”的领会，也没有什么问题，因为若去掉这个“是”字，比如“‘存在’什么？”意思就完全不一样了。也就是说，在这个问句中，“是”这个词起着至关重要的作用。但是，怎么能说这句话依赖于对“是[在]”的理解呢？括号中的这个“在”是从哪里跑出来的呢？难道说这里的“是”含有“在”的意思吗？这个句子的意思会依赖于放在括号中的这个“在”的意思吗？无论如何，我看不出有这样的意思，“‘存在’在什么？”这句话肯定是不通的。因此我不明白为什么要加上这个“在”。也许这里体现出海德格尔的睿智，他以这种方式表达出常人所无法理解和想象的东西。可是他为什么随后又只说“我们还不能从概念上明确这个‘是’意味着什么”呢？就是说，为什么在随后的说明中这个“在”又突然消失了呢？如此变化，真是令人莫测啊！

      以上无法理解的两点，既有表述上的问题，也有内容上的问题。由此则产生了另一些无法理解的问题。

      如果我们仔细阅读，则可以看出，这段话包括两部分内容，一部分是理论性说明，另一部分是举例说明。在理论性说明中，海德格尔明确指出，“提问存在的意义”和“获得存在的解释”这两点是“从对存在的某种领会中发生出来的”。在举例说明中，海德格尔则借助“‘存在’是什么？”这样一个具体的关于存在的发问来进行说明，就是说，他给出了对存在发问的具体表达形式。而从“‘存在’是什么？”这个问题来看，它显然是在探讨“存在”的意义，因为这是非常明确地在对“存在”发问。从这个例子可以明显看出，它包含了对“存在”的提问，既然是问，当然是为了获得对存在的解释，因此这个举例说明与理论性说明的这两部分内容应该是一致的，因而应该是相符合的。但是，按照海德格尔的理论性说明，还有更为重要的一点，这就是在这样的发问中，我们本来应该以某种方式利用存在的意义，因为我们已经活动在对存在的某种领会之中了。但是，从举例说明来看，实际情况却不是这样。我们看到，在关于存在的发问中，使用的词不是“存在”，而是“是”，被利用的并不是“存在”的意义，而是“是”的意义。在这种情况下，我们怎么会有对存在的领会呢？我们又怎么会活动在对存在的领会之中呢？尤其是，即使海德格尔本人的论述也发生了变化，他不过是在被利用的这个“是”后面以括号的方式加了一个“在”。不知道这个“在”是什么意思，也不论它会是什么意思，至少海德格尔明确告诉我们的是，我们不能确定这个“是”意味着什么。也就是说，在他的明确说明中，我们只看到“是”，根本看不到“在”。按照这个发问，按照关于它的论述，正确的理解似乎应该如下：发问存在，可利用的乃是“是”，而且我们总是处在关于是的某种领会之中。可是这样一来，前面的论述就都不对了：明明是在论述存在，并说要依赖于对“存在”的领会，怎么最终却变成要依赖于对“是”的理解了呢？这怎么可能呢？

      此外，这里还有另一个更为严重的问题。对“存在”进行提问，却要依赖于对“是”的领会，那么，“存在”和“是”，它们哪一个是更基础的呢？在我看来，最后这个问题是致命的。在前面关于译文1的讨论中，我们曾经提到过这个问题。这个问题如果说仅从要“如是而存在”这样的论述还看得不是那样清楚的话，那么从这里关于依赖于对“是”的领会的论述则可以看得非常清楚。既然探讨存在的意义，还认为它是最普遍的，可又要通过“是”来理解它，那么它还是最基础的概念吗？确切地说，“存在”和“是”，究竟哪一个是更为基本、更为基础的呢？

      译文1和2对于理解关于“存在”的论述显然是至关重要的。在如此重要的讨论中，却存在这么多无法理解的问题，这难道是正常的吗？

      二、“是”与发问的结构

      我认为，以上译文确实有许多难以理解的地方，但是，这些问题并不是海德格尔本人的问题，而是由中文翻译造成的。如果把其中的“存在”及其相关概念修正翻译为“是”，则会消除以上问题。下面，让我们根据这样的认识，重新探讨这两段译文。这一节的题目是“是之问题的形式结构”。这一小节一开始，海德格尔就明确地说：

      [译文1*]是的意义问题还有待提出。如果这个问题是一个基本问题或者说唯有它才是基本问题，那么就必须对这一问题的发问本身做一番适当的透视。所以，我们必须简短地讨论一下任何问题都一般地包含着的东西，以便能使是的问题作为一个与众不同的问题映入眼帘。

      任何发问都是一种寻求。任何寻求都有从它所寻求的东西方面而来的事先引导。发问是对是者“是怎么一回事和是如此这般”[Dass-und Sosein]的认识性寻求。这种认识性寻求可以成为一种“探索”，亦即对问题所问的东西加以分析规定的“探索”。发问作为“对……”的发问而具有被问的东西[Gefragtes]。一切“对……”的发问都是以某种方式“就……”的询问。发问不仅包含有被问的东西，而且也包含有被问及的东西[Befragtes]。在探索性的问题亦即在理论问题中，被问的东西应该得到规定而成为概念。这样(dann)在被问的东西中还有被问出来的东西[Erfragtes]，这是真正的意图所在，发问到这里达到了目标。这种发问本身乃是某种是者即发问者的行为，发问本身具有是的某种本己的特征。发问既可以是“问问而已”，也可以是明确地提出问题。后者的特点在于：只有当问题的上述各构成特征都已经透彻之后，发问本身才透彻。

      是的意义问题还有待提出的。所以，我们就必须着眼于上述诸结构要素来讨论是的问题。(s.5)

      这段译文是第二节的开场白，共分三小段。第一小段说明，要讨论任何问题都包含的东西，然后再讨论是的问题，以此显示出是这个问题的独特性。第二小段集中讨论了发问的方式。第三小段说明，基于以上讨论，就可以进入关于是的问题的讨论了。可以看出，海德格尔在这里想说明的主要是人们一般提问的方式，而不是对是的提问方式。他想通过这种关于一般发问的方式的说明，来得到提问的一般要素和特征，然后依据所得到的这些要素和特征，再来考虑关于是的发问的问题，看它是不是也具备这些要素和特征，这样也就可以说明它与一般的问题是不是相同，因而也就可以说明它本身是不是具有独特性，有什么独特性。这些意思大致是可以体会出来的。通俗地说，一般问题该怎么问，对是也就怎么问；先弄清楚一般问题的提问方式，再以是的提问方式与它对照；这样人们就可以看出是这个问题的一些专门特征。海德格尔的这些意思尽管可以理解，一些具体的讨论还是需要我们认真去分析的。下面我们重点分析第二小段，它也是这段引文的重点。

      这一小段重点讨论发问。首先它说明，发问是一种寻求，而且这种寻求可以成为一种探索。在这一说明中，关键在于对寻求的两点说明。一点是对是者“是怎样一回事”的认识，另一点是对是者“是如此这般”的认识。这段话的原文是“Dass-und Sosein”。“Sosein”本身是清楚的。它由So和sein两个词组合而成。“Dass”后面有一条短横线，表示与后一个“So”同位，因而表明与“So”一样，也与“sein”相连。因此它也是清楚的，即“Dasssein”；与“Sosein”相一致，即“Dasssein”。明确了Dasssein和Sosein这两个词的构成方式，有助于我们理解这两个词的意思。①

      从字面上看，Sosein由So和sein组合而成，实际上是“ist so”的名词形式。这里，ist是系动词，so处于表语的位置，表示可以处于系词后面作表语的词，当然，这样的词可以是名词、形容词或其他形式的词组等等。名词可以表达事物，形容词可以表达性质，其他形式的词组还可以表达其他东西，比如表达关系、位置、时间等等。因此，“ist so”的意思是“是如此这般”。它的名词表达，即“Sosein”，尽管语法形式不同，意思却没有什么不同，也不应该有什么不同。

      Dasssein则由Dass和sein组合而成，实际上是“ist，dass”的名词形式。这里的“ist”依然是系词，“dass”也同样处于表语的位置，但是后者与“so”有重大区别。Dass是一个语法词，后面要跟一个完整的句子。确切地说，它引导一个句子作表语，这样的表语被称之为表语从句。句子不是表示事物、性质或关系等等，而是表示一事物是什么，一事物有什么样的性质，一事物与其他事物有什么样的关系，等等，简单地说，即是表示一事物是怎么一回事。因此，“dass”的意思是“一事物是怎么一回事”。应该看到，“ist，dass”不仅省略了跟在dass后面的句子，而且省略了ist前面的主语，如果把这个主语看作“一事物”，则与从句中的“一事物”重合，因而也可以省略。这样，“ist，dass”的意思大体上是“是怎么一回事”。Dasssein乃是“ist，dass”的名词形式，因此，尽管语法形式不同，意思应该是一样的。

      关于Dasssein，人们可能会有不同的理解，因而可能会有不同的翻译方式。但是至少应该看到，无论怎样理解，这里的“Dasssein”中的“sein”与“Sosein”中的“sein”乃是一样的，它们都是系词，后面都要跟一个表语，无论是以名词、形容词或其他形式的词所表示的表语(so)，还是以从句所表示的表语(dass)。在海德格尔的说明中，大概这一点是最重要的，也是他的用意所在。

      联系第一小节谈到的“任何问题都一般地包含着的东西”，我们就会认识到，海德格尔关于Dasssein和Sosein的论述不是随意的。这样一种考虑，似乎至少从语言形式上穷尽了与Sein相关的可能性，因而才可以表达出他所说的任何问题都包含的东西。

      接下来是关于发问的具体说明。这里说到三种不同的要素：被问的东西(Gefragtes)，被问及的东西(Befragtes)，被问出来的东西(Erfragtes)。这三个词有共同的词根“fragen”(问)，因此都与它相关。三个不同的词头无疑表明这三个词的意思是不一样的。这种谈论问题的方式充分体现出海德格尔驾驭文字的本领，当然也不能说完全没有摆弄文字的意味。然而，对我们来说，最重要的还是要弄明白他通过这种语法变化和文字差异究竟说出一些什么不同的东西来。

      既然是发问，一定会有针对性，因此，说发问具有被问的东西也就比较容易理解。尽管如此，海德格尔在这里还是做出了解释：发问是“对……”的发问。这无非是说发问有对象。因此，被问的东西在发问中是显然的。

      那么什么是被问及的东西呢？难道被问的东西不是被问及的东西吗？既然字面上有所区别，似乎也就不能简单地把它们划等号，而按照海德格尔给出的解释，即“对……”的发问就是以某种方式“就……”的询问，它们确实是不同的。这里我们可以看出，“对……”(nach…)的发问，指的是针对一个对象，即某种东西；而“以某种方式”(in irgendeiner Weise)“就……”(bei…)的询问，指的是问的方式。这里不太清楚的地方是，“以某种方式”与“就……”之间是什么关系？

      “bei”是一个介词，可以表示“在……”、“就……”、“通过……”等等。其后的删节号表明，这里有一个空位，因而要有与之相关的补充。至于用什么来补充，仅从这个词本身是看不出来的。但是从这个介词的形式可以看出，并可以依具体语境来判断，比如“在某一位置”、“就某一方面”、“通过某一途经”等等。认识到“bei”这个介词的这种特征，我们就可以具体地问，所谓以不同的方式与“就……”是什么关系？是指与这些要补充的东西有什么关系吗？尽管有上述含糊之处，被问及的东西与被问的东西之间的区别似乎还是可以看出来的。为了明白这里的问题，我们可以设想一个具体问题。比如我们问：苏格拉底是哲学家吗？苏格拉底是聪明的吗？苏格拉底是柏拉图的老师吗？苏格拉底是邋邋遢遢的吗？这些问题无疑都是对苏格拉底的发问。但是被问及的东西是什么呢？我们可以说，第一个问题是就苏格拉底是什么的询问，第二和第四个问题是就他的某种性质的询问，第三个问题是就他和柏拉图的关系的询问。这里比较清楚的是，对苏格拉底的发问与发问所涉及的东西乃是不同的；而不太清楚的是，发问的“以某种方式”是指什么？“就……”又是指什么？二者之间有什么样的关系？这些不同方面是不是表明这些询问的方式是不同的？因而我们可以问，海德格尔所说的“以不同的方式”和“就……”之间的关系是什么？

      最后需要考虑的是被问出来的东西。字面上就可以看出，被问出来的东西与被问的东西是不同的。比如根据前面的例子，被问的是苏格拉底，被问出来的东西却一定不是苏格拉底，很可能会与发问所涉及的东西相关。但是，这只不过是一些字面上的理解。我们还是应该看一看海德格尔自己的说明。

      海德格尔对被问出来的东西似乎有两点说明。其中一点是在谈到“被问出来的”这个术语的这句话之前。按照他的说法，在探索的问题中，被问的东西应该得到规定，应该被表达出来。由于前面说过从发问到寻求再到探索，因此这里在字面上说的是“探索”，实际上说的还是“发问”。值得注意的是，海德格尔在这里还说到被问的东西应该被表达出来(soll…zum Begriff gebracht werden)。那么，这里所说的“被表达出来”是什么意思呢？从字面上看，被表达出来的东西一定与被问的东西相关，那么，它们是不是也与被问及的东西相关呢？当然，我们也可以简单地问：被问出来的东西是什么呢？

      另一点说明是在含有“被问出来的”这个术语的这句话之中。这里，海德格尔对被问出来的东西有两种解释。一种解释(在原文中是以介词的方式)表明，在被问的东西中，被问出来的东西乃是真正想得到的东西。另一种解释(在原文中是以从句的方式)表明，在被问出来的东西这里，发问达到或实现了目的。由此可以看出，就发问而言，被问出来的东西不仅是不可或缺的，而且是至关重要的，甚至是最重要的。这一点其实不难理解，因为提问的目的主要在于寻求解答。因此通过对某种东西发问而得到关于这种东西的解答，乃是非常自然的事情。这里的区别似乎不过在于海德格尔对发问作出区别，他似乎把通过发问而得到的解答称之为被问出来的东西。

      必须看到，上述两个句子之间有一个联结词“dann”。如果如同修正的译文2*把它理解为“这样”，那么前后这两个句子就有一种前提和后果的关系。这表明，被问出来的东西就是在发问中应该被表达出来的东西。如果如同英译文把它理解为“此外”，②那么前后两个句子的关系是并列的。在这种情况下，我们就要考虑，“被表达出来的”与“被问出来的”有什么关系？它们是不是一回事？如果不是，它们的区别是什么？

      综上所述，尽管有这样或那样不太清楚的地方，我们至少看到，海德格尔区别出被问的东西、被问及的东西和被问出来的东西；而且这三种东西确实是有区别的。

      值得注意的是，海德格尔在第一小段得出了这个结论，而在第二小段结尾处他又说到，发问有一种自身独特的是的特征。从他的论述来看，发问有这种特征似乎是因为发问乃是一种是者即发问者的行为。这样，与这句话相关的就有两个问题。一个问题是，这句话本身是什么意思？另一个问题是，这句话与此前关于结构的论述、与其后关于结论的论述有什么关系？

      说发问是发问者的行为，对我们来说不会有什么理解上的问题。但是在这个语境中，说发问有一种是的自身独特的特征，却会有问题。发问者发问，怎么会有是的特征呢？而且这种特征又怎么会是自身独特的呢？我们看到，这里说发问乃是是者的行为，并且用发问者解释了是者。这样，我们似乎可以认为这里是说，在是者的行为中有一种是的特征。即便如此，我们大概依然还会有无法理解的问题：这种是的特征究竟是什么？如果说这样的问题仅仅是字面上的，并不太严重，那么联系上下文，就不是这样了。这种关于是的论述，与此前谈到的三种结构，以及与随后谈到的如何透彻地理解发问，究竟有什么关系呢？直观上看，它们之间简直可以说没有什么关系。然而，如果没有什么关系，为什么要把这句话放在这里呢？

      在我看来，这里可能会没有直接的关系，但是不一定没有间接的关系。我们看到，在论述这三种结构之前，海德格尔从寻求的角度对发问进行了说明。在这个说明中，他谈到“是怎么一回事”和“是如此这般”，并且把这样的寻求说成是探索。若是联系这些说明来看，说发问具有一种是的特征，似乎也就没有什么不可以理解的了。既然发问会涉及一事物是怎么一回事或一事物是如此这般，发问当然会与是相关，因而会有是的特征。至于说这种特征是不是独特的，或者，这种独特的特征是不是“是怎么一回事”或“是如此这般”，乃是可以讨论的。但是至少可以看出，它们总还是相关的。

      三、对“是”的发问

      通过以上说明，海德格尔得到了关于发问的一般认识，获得了一般发问的结构要素。现在要做的则是从这些结构要素出发来讨论是的发问，通过把是的发问放在一般发问的结构框架下，使我们更好地认识是的发问的结构，并由此获得是的意义。

      [译文2*]作为一种寻求，发问需要一种来自它所寻求的东西方面的事先引导。所以，是的意义已经以某种方式可供我们利用。我们曾提示过：我们总已经活动在对是的某种领会中了。明确提问是的意义、意求获得是的概念，这些都是从对是的某种领会中生发出来的。我们不知道“是”说的是什么，然而，当我们问道“‘是’是什么？”时，我们已经栖身在对“是”的某种领会之中了，尽管我们还不能从概念上明确这个“是”意味着什么。我们从来不知道该从哪一视野出发来把握和确定是的意义。但这种平均的含混的对是的领会乃是事实。(s.5)

      这段话有几层意思。一是仍然是在谈论一般性的发问；二是提出了我们利用是的意义；三是通过讨论“‘是’是什么？”这个问题而说明，我们领会是的意义，但是我们不知道它的意义是什么，这样就说明，是的意义乃是含混的。由于这段话明确讨论了是的意义，并且是以“‘是’是什么？”这样一个非常明确的问题为例来讨论，因此对于我们理解对是的发问以及与它相关的问题具有重要意义，应该值得我们重视和认真对待。下面就让我们认真讨论这三层含义。

      第一层意思不过是重复译文1*第二小段的第一句话，不会有什么理解上的问题，我们可以暂且不予考虑。

      第二层意义说明，在发问的时候，我们有是的意义可以利用。这层意思本身(至少字面上)是清楚的，没有什么理解上的问题。值得注意的是它以一个联结词“所以”(daher)引出，这样，它与前一句关于发问作为寻求和需要事先引导的说明就有了一种联系，于是也就产生一个问题：从前一句话如何能够得出这样一个结论？无论是发问作为寻求，还是发问需要某种事先引导，如何能够得出我们已有是的意义可以利用这样一个结论呢？接下来的一句表明，前面曾经提示过，我们总是生活在对是的某种领会之中。这句话无疑可以作为第二层意思的注释：既然生活在对是的领会之中，拥有对是的理解也就不会有什么奇怪的了。基于这样的说明，似乎我们当然也可以认为，无论寻求什么，不管需要什么东西做事先引导，都可以算是生活在对是的某种领会之中，因此也就有是的意义可以利用。只不过这对前面的“所以”充其量是一种间接的说明，而不是直接的说明。为了更好地理解这里的说明，我们需要结合译文1*的相关论述，看一下是不是可以得到一些直接的说明。

      前面说过，译文1*对发问这样一种寻求做出了两方面的说明：一方面乃是“是怎么一回事”，另一方面则是“是如此这般”。若是把这两方面的说明考虑在内，似乎也就可以理解，为什么从发问可以得出有是的意义可用。因为这两方面的说明隐含着“是”，因而借用了“是”的意义。认识到这一点，也就可以看出，译文2*关于“所以”的说明不会有什么问题，因为它是基于译文1*的说明。当然，译文1*本身的说明是不是有问题乃是可以讨论的；如果那里的说明有问题，译文2*这里的论述也就会有问题。不过，海德格尔似乎认为这样的论述没有问题。在我看来，不管译文1*的论述是不是有问题，有什么样的问题，它至少为译文2*这里的论述埋下了伏笔。换句话说，不管海德格尔的论证是不是有问题，他的叙述方式还是可以理解的。

      基于前两层意思，第三层意思就比较容易理解了。“‘是’是什么？”乃是一个问句，显然是对是的发问。这个问句的方式无疑是最普通最常见的，它符合通常的发问方式。它对是进行发问，询问它的意义。这个被问的是就是这个问句中引号中的那个是。但是在这样问的时候，这个问句又用到是，因此它本身依赖于所使用的这个是的意义。这个被用到的是即是这个问句中的系动词，亦即句子中的第二个是，也是被加了重点符号(海德格尔本人用斜体)予以强调的那个是。因此，这个例子是非常明显的，是没有歧义的。我们不知道是的意义，因此我们对它发问，问它是什么；但是我们在这样问的时候，却已经对它有了某种理解，因为我们在明确地使用它。海德格尔的疑问是明显的，也是有道理的：如果没有任何理解，我们又怎么能够使用它呢？所以，这个问句展现了一个问题：一方面我们问是的意义，这表明我们不知道它的意义；另一方面我们在问它的时候又使用了它，这表明我们似乎好像知道它的意义。这个问题显示出一种矛盾，它说明了探讨是的意义所面临的问题。在海德格尔看来，这说明是的意义乃是含混的，不确定的。因而人们对它的理解实际上也是这样的。

      为了更好地理解这层意思，还可以从德文的角度简单探讨一下围绕这个举例的说明。这个例子是“‘是’是什么？”。其中有两个“是”。前一个“是”的德文乃是名词“Sein”，后一个“是”的德文乃是动词“ist”。海德格尔关于它的说明也有两句。前一句是“我们不知道‘是’说的什么”，后一句是“我们已经栖身在对‘是’的某种领会之中了，尽管我们还不能从概念上明确这个‘是’意味着什么”。前一句中的“是”的德文乃是名词，即“Sein”。后一句中有两个“是”。前一个“是”的德文乃是动词“ist”，后一个“是”的德文则是名词“Sein”。围绕这个例子，结合这两句说明，我们可以看出，在海德格尔的论述中，名词的“是”与动词的“是”乃是同一个词。它们的语法形式不同，其意义却是一样的。谈论它的时候，它就是名词，用它的时候，它就是动词。而且，如果当真要论述它们之间的关系，一定是名词的意义来自动词的意义。按照这里的说明，我们不知道“是”说什么，因此我们会问它是什么，但是这样一问就会用到它，因而也就有了对它的理解。所以，考虑是这个词的意义时，它的动词形式的意义乃是最根本的。

      在我看来，海德格尔这一段关于“是”的发问的论述，对于理解他关于“是”的论述，对于理解他所说的“是”这个概念，乃是至关重要的。

      四、我的看法

      以上我们讨论了Sein und Zeit导论中第一章第二节开始的几段话。我们看到，为了讨论关于Sein的问题，海德格尔探讨了发问的活动和一般的发问结构，并且据此谈论了关于Sein的发问的结构。有了这两种发问结构的对照，可以显示出Sein的问题的特殊性，并且同时也为以后探讨Sein的问题提供了一种途径：即依循被问的东西、被问及的东西和被问出来的东西这些结构要素来思考有关Sein的问题。由此可见，在海德格尔关于Sein的论述中，结构是一个非常重要的视角，起了非常大的作用。现在需要说明的是，通过海德格尔关于发问结构的论述可以看出，他所说的Sein乃是“是”，而不是“存在”。

      首先我们看发问的一般结构。海德格尔在发问的结构中区别出被问的东西、被问及的东西与被问出来的东西。从字面上看，这些结构要素与Sein没有任何关系，而且似乎也不会有什么关系。但是，如前所述，海德格尔在论述发问结构时说：“发问是对是者‘是怎么一回事和是如此这般’[Dass-und Sosein]的认识性寻求”。我们也许不能说这是海德格尔对发问的定义，但是这至少是他对发问的描述说明，因此这句话对于理解海德格尔所说的发问至关重要。正是在这里，我们看到了关于Sein和与Sein相关的论述：“是者”(Seiende)、“是怎么一回事和是如此这般”[Dass-und Sosein]。由此也就看出，海德格尔关于发问结构的论述实际上是与Sein相关的。他所说的Sein乃是“是”，而不是“存在”，因此这里与发问结构相关的讨论也是与“是”相关的，而不是与“存在”相关的。

      其次，在谈论一般发问的过程中，海德格尔谈到了“认识性寻求”，由此还引出了“探索”。从字面上可以看出，“认识性寻求”乃是与“是”相关的，因而由它引出的“探索”也会与“是”相关。这些在字面上似乎不会有什么理解上的问题。一事物是怎么一回事，一事物是如此这般的，当然可以与认识有关，因而与人们的探索相关。③

      认识到这一点，有助于我们看出，海德格尔关于Sein这个问题的探讨的实质究竟是什么。他所说的发问，并不是随意的、任意的，而是与认识相关的。一方面，“一事物是怎么一回事”，或者“一事物是如此这般”，可以确实表达或反映出我们的认识，因而与认识相关。另一方面，从认识出发，“是什么？”“是怎样的？”大概是基本的提问方式，“是如此这般”、“是这样的”则是对基本提问方式的回答，也是对基本认识的表达。因此，“一事物是怎么一回事”、“一事物是如此这般”确实是与认识相关的论述。

      若是深入思考，则还可以看出，这里的论述似乎与语言相关。这是因为，无论什么认识、如何认识，都是需要通过语言来表达的，或者，从语言的表达方面可以看出人们的认识是怎么一回事。因此我们可以看出，若是不结合语言来考虑，这里所说的Sein乃是“是”，而不是“存在”；若是结合语言来考虑，这里所说的Sein也是“是”，而不是“存在”。或者换一种方式，从“是”的角度出发，我们不仅可以看出这里的考虑与认识相关，而且可以看出这里的考虑与语言相关。而从“存在”的角度出发，我们大概无法看出这里的考虑会与认识相关。或者，即使可以看出这里的考虑会与认识相关，我们大概也看不出这里的考虑会与语言相关。其原因很简单，“是”这个词可以表达出认识和语言方面的考虑，但是“存在”这个词却无法表达出认识和语言方面的考虑。这是因为，它无法表达海德格尔所说的Dasssein(是怎么一回事)和Sosein(是如此这般)所要表达的意思。④

      前面说过，关于发问的结构的探讨乃是关于一般发问的结构的探讨，这样的探讨乃是为说明关于是的发问做准备。相比之下，关于是的发问的结构的探讨乃是一种具体的发问探讨。我们看到，在关于Sein的问题的论述中(译文2*)，海德格尔再次提到了“寻求的东西”和“事先引导”，因而Sein的意义已经以某种方式可供我们利用。他对这一点的解释即是我们总是生活在对Sein的领会之中。正因为这样，当我们问“‘是’是什么的时候？”，我们已经栖身在对是的领会之中了。他甚至把这样的对是的领会称为事实。⑤

      从字面上看，海德格尔在谈论发问，并且从一般的发问过渡到对是的发问。但是，如果仔细分析则可以看出，这两种发问有一个共同点，这就是对是的领会。在关于发问结构的论述中，海德格尔谈到发问乃是试图认识一事物是怎么一回事，一事物是如此这般的，但是没有说发问依赖于对是的领会。而在论述从一般发问到对是的发问的过程中，他说这样的发问要有一种来自它所寻求的东西的事先引导。这样就有了是的意义可以利用。由此我们可以看出，他说的这种起事先引导作用的东西一定在“是怎么一回事”和“是如此这般”之中。由于他明确地说出这种东西为“是”，这就使我们清楚地看出，这也就是“是怎么一回事”和“是如此这般”中的那个“是”。而在过渡到对是的发问，即“‘是’是什么？”之后，我们看到的就不是关于一般发问的论述，因而不是关于一般的“是怎么一回事”或“是如此这般”的论述，而是一个具体的发问，也就是说，我们看到了“是什么？”这样一个具体的发问。认识到这一点，我们显然可以看出，这与此前所说的“是怎么一回事”或“是如此这般”乃是一致的，因为关于“是什么？”的回答一定会表明“是怎么一回事”或“是如此这般”的。但是，由于这个具体发问的对象乃是“是”，因此关于是的发问这个问题的独特性就更加明显地突出出来，因为被问的东西与起事先引导作用的东西重合了。换句话说，对是的领会有助于我们认识一般事物，但是却不一定会有助于我们认识是本身，因此对是的领会会有助于我们关于一般发问的考虑，却不一定会有助于我们关于是的发问的思考。当然，由此也可以看出，关于是的问题乃是有独特性的，与其他任何问题都不相同。

      从前面的论述可以看出，关于是的发问实际上是一个具体发问的例子，它使我们可以看出是这个词在语言中的使用方式以及海德格尔对它的考虑。因此我们说海德格尔的相关讨论可能会有关于语言的考虑。现在需要说明的是，在有关一般发问的说明中，是不是也有与语言相关的考虑？从字面上看，“寻求”、“事先引导”，甚至“是的意义”等等这样的说明，似乎都无法与语言联系起来，但是，“是的意义已经以某种方式可供我们利用”这一句话该如何理解呢？确切地说，“是的意义”如何能够被我们利用呢？所谓“以某种方式”中的“方式”指的又是什么呢？我的意思是说，具体哪一种方式并不重要，重要的是这里所说的方式怎样体现出来，我们能够把什么称之为方式，并且通过它来把握是的意义。联系到此前关于发问乃是对事物“是怎么一回事和是如此这般”的说明，我们大致可以看出，“是怎么一回事”(Dasssein)可以是一种是的方式，“是如此这般”(Sosein)也可以是一种是的方式。这些论述是不是直接关于语言的，因而是不是直接含有关于语言的考虑，姑且不论，但是这里的论述与语言相关，因而有关于语言的考虑却是毫无疑问的。最保守地说，海德格尔至少是通过与语言相关的区别，通过与“是”相关的不同表达方式来说明是的意义的。

      我们也许可以换一种方式来说明海德格尔想说明的问题。无论“是”的意义是什么，语言中的“是”这个词却是具体的、可以使用的。在使用的过程中，人们可以看到它的不同方式。这些不同的方式可以表现出不同的含义。但是无论如何，人们在使用它的过程中似乎从来没有怀疑过它的意义，因而人们似乎有一种对它的先天理解。但是，一旦人们对它的意义进行发问，人们就会发现，这里其实是有问题的。比如，人们对一般事物问“是什么”的时候，无论人们问它们是怎么一回事，还是问它们是不是如此这般的，都不会有什么问题，但是当人们问“‘是’是什么？”的时候，问题就出现了。因为从字面上就可以看出，这里被问的东西与询问所依据的东西是相同的。这样似乎也就说明，是的意义的问题不仅是独特的，而且是至关重要的。人们似乎理解它的含义，但是一旦追问它的含义，人们就会发现，这里其实是有问题的。由此还可以说明，在那些似乎没有问题的发问中，即我们似乎先天地理解了是的意义并且以某种方式使用它的时候，它的意义问题及与它的意义相关的问题，实际上也同样是存在的。

      最后还需要指出一点。在前面关于译文1*的讨论中，我们只谈了第二小段，而没有谈论第一小段。现在则可以简要地考虑一下第一小段的论述。

      第一小段明确地说明，要“讨论一下任何问题都一般地包含着的东西”。而第二小段是从“任何发问”开始的。因此，第二小段的讨论是与第一小段的论述直接相关的。如果对照一下德文，则会发现，前者所说的“问题”与后者所说的“发问”，乃是同一个词，都是Frage。如前所述，“任何发问”表明了这个问题的普遍性，同样，“任何问题都一般地包含着的东西”也表明了所讨论问题的普遍性。在这种情况下，理解海德格尔关于发问结构的讨论，就必须始终意识到这种普遍性，并且把它放在首位。

      从前面的讨论可以看出，与发问和探寻相关，海德格尔谈论了“是怎么一回事”和“是如此这般”。这显然是与普遍性相关的。有关这方面的思考，前面已经说过许多，因此不必重复。这里我想说的是，即使不考虑海德格尔的论述，不考虑前面那些关于他的论述的思考，仅从普遍性的角度出发，我们将会得到一些什么样的结果。

      我要问的是：发问怎么会与“存在”相关呢？发问的结构又怎么会与“存在”相关呢？人们确实可以问与“存在”相关的问题，人们的发问中也确实可以出现“存在”，比如“某物存在吗？”问题是，与“任何问题”相关的难道会是“存在”吗？“任何问题都一般地包含着的东西”难道会是“存在”吗？“苏格拉底是希腊哲学家吗？”“他是柏拉图的老师吗？”“他是邋遢的吗？”等等这样的问题，以及诸如此类的问题，难道会与“存在”有什么关系吗？我不这样认为。在我看来，从普遍性的角度说，发问与“是”相关，而与“存在”没有什么关系；发问的结构含有“是”，而不含有“存在”。尤其是，发问与认识活动相关，因此“是什么？”乃是基本的发问方式。与“存在”相关的发问，只是某一类特定的发问，不具有普遍性。只要认识到这些情况，就可以看出，海德格尔关于发问结构的探讨乃是与“是”相关的，而与“存在”没有什么关系。从具体的论述看，他谈论的“是怎么一回事”和“是如此这般”显然与是相关，而非与存在相关；从抽象的论述看，他谈的“任何发问”及其“一般具有的东西”则不会与存在相关，而会与是相关。如果再把二者结合起来，我们就会非常清楚地看出，他的论述乃是与“是”相关，而不是与“存在”相关的，而且，他的论述也只能与“是”相关，而不能与“存在”相关。

      理解海德格尔关于Sein的发问结构的探讨，是理解他关于Sein及其相关问题的探讨的重要而关键的步骤，也是理解西方哲学中有关being问题具体的活生生的例子。我希望，本文的讨论能够给人以启示，从而有助于人们深入思考，应该如何理解海德格尔所说的Sein，应该如何理解西方哲学中的being以及与它相关的问题。

      注释：

      ①从这里引入这个词的角度看，在Dass和sein之间可以不加“-”，因而是“Dasssein”。在行文论述中，为了突出Sein这个结构特征，有时候可能也会加上“-”，因而形成“Dass-sein”。在我看来，加与不加这条短横线，除了可以突出确定这种句式和结构外，意思是一样的。

      ②实际上，英译文为“so in addition to”(参见Heidegger，M.：Being and Time，中国社会科学出版社1999年版，第24页)。其中的“so”和本文的理解差不多，而“in addition to”的意思为“此外”。英译文把二者合并起来，以此来翻译这里的“dann”，也许是因为译者把握不准海德格尔的意思。

      ③本文讨论仅限于所引译文。若是可以引申讨论，比如，考虑到海德格尔后来关于“在-世界-之中-是”(in-der-Welt-sein)的论述，则可以看得非常清楚，海德格尔关于Sein的探讨要与认识相关，这是毫不奇怪的。

      ④应该看到，关于语言的考虑对于理解Sein及其相关问题乃是至关重要的，而且海德格尔确实在许多地方有许多关于语言的考虑。那么，这里有没有关于语言的考虑？限于篇幅和所引译文，我仅仅强调指出，关于认识与语言的区别和关系，海德格尔是不是有这样清楚的认识，姑且不论，但是他的论述至少给我们留下了可以这样认识和思考的空间。因此，即使仅从翻译的角度来考虑，我们也应该保留这种理解的可能性，也就是说，我们应该至少在字面上保留这样理解的空间。

      ⑤海德格尔从该书开篇即谈到对Sein的领会，并且在译文1*之前多次谈到它。参见s.2，s.3，s.4。

      　　【参考文献】

       [1]王路.“是”、“是者”、“此是”与“真”——理解海德格尔[J].哲学研究，1998，(6).

      [2]王路.是与真——形而上学的基石[M].北京：人民出版社，2003.

      [3]王路.一脉相承的“是”——以海德格尔的讨论为例[J].哲学分析，2010.

      [4]王路.读不懂的西方哲学[M].北京：北京大学出版社，2011.

      [5]海德格尔.存在与时间[M].陈嘉映，王庆节译.熊伟校.陈嘉映修订.北京：生活·读书·新知三联书店，2006.',
      "Elizabeth Bishop 의 詩 硏究  시야의 확대를 통해 빚어내는 사물에 대한 예리한 묘사와 따뜻한 사랑.

      Ⅰ Elizabeth Bishop(1911 - 1979)은 미국 내에서도 최근에야 주목받는 시인중 한 사람이다. Perkins는 서슴지 않고 Bishop을 Warren 이나, Roethke 등의 시인들 중에서 가장 뛰어나다고 하였다1). 이런 평판에 대해서는 최근에 Bishop論을 쓴 Travisano를 비롯하여 대부분의 평자들이 기본적으로 동의를 하고 있다. Travisano는 이를 좀 더 구체적으로 밝혀 Bishop이 New Critics파도 아니고 고백파(the Confessional)도 아니며 Beat도 아니고 학술파(The Academic)도 아니라고 하였다2). 확실히 Bishop이 Yeats, Pound, Eliot과 같은 격의 시인이 아니라고 할지라도 적어도 Emily Dickinson, G. M. Hopkins와 같은 독자적 영역과 위치를 차지하고 있는 시인의 반열에 들 수 있다는 것이 그들의 견해이다.

      Bishop은 자신이 성장해온 독특한 환경과 기질 그리고 病歷에 기인한 자폐에 가까운 철저한 자아탐구에서 시작하여 인간과 자연의 보편적 문제에 이르기까지 대상을 철저하게 파고들며 냉정한 눈으로 관찰자의 자세를 유지했고 그 과정을 통해 사물의 핵심을 집어내는 정밀한 묘사력과 독자의 상상력을 자극하는 뛰어난 직관과 상징이 그의 시 세계를 풍부하게 해 주었다.  이러한 성향의 Bishop은 때로는  자연스러움과 즉각적으로 반응하는 형태의 시에 沈着하면서도 시가 보여줄 수 있는 정밀성의 한계를 시험하기 위해 단 한 개의 시를 쓰기 위해 몇 년을 보내기도 했다3). 이처럼 Bishop의 시적인 묘사에 관한 정밀성은 그 유래를 찾아보기 힘들만큼 정교하지만 자칫 이것은 그의 시 세계가 기계적이고 편협하며 지나치게 즉물적이라는 오해를 불러일으킬 여지가 있다. 그러나 이러한 선입견은 The Man-Moth나 The Weed를 통해서 극복되고 있음을 확인할 수 있다. 오히려 정밀하고 섬세하며 사실적 묘사에 바탕을 둔 시가 제공해주는 상상력이야말로 시를 통해서 고양되는 인간정신의 추구방향과 일치한다고 볼 수 있다.   Bishop은 1911년 Massachusetts의 Worcester에서 태어났다. 부친은 보스톤 유수한 가문의 부유한 건축가였고 모친은 Nova Scotia출신의 침례교인으로서 몹시 병약한 기질을 지니고 있었다. 부친 William T. Bishop은 Bishop이 8개월 됐을 때 사망했고 그 충격으로 그의 어머니 Gertrude Bishop은 정신적 질환을 앓다가 Bishop이 5살 되던 해에 영구히 정신병원에 격리되었으며 1934년 사망하기까지 모녀간의 만남이 한번도 이루어진 적이 없었다고 한다.  Bishop은 고아나 다름없는 환경에서 6세까지는 Nova Scotia에서 외조부모와 살았으나, 갑자기 친조부모가 찾아와 좀더 좋은 환경으로 옮겨간다는 구실로 그를 생가인 Massachusettes 의 Worcester로 강제로 데려갔다. 그러나 완고하고 무뚝뚝한 친조부모의 생활은 Bishop인 남긴 회고적인 산문 'The Country Mouse' 에 “나는 누구의 동의도 없이 조부모에 의해 가난과 시골티를 벗어야한다는 이유로 Worcester로 옮겨져야 했다. 그곳에서 나는 나 자신이 점점 늙어가고 있으며 심지어 죽어가고 있다는 느낌을 가졌었다. 그 곳의 생활을 고립되었고 지루했었다. 밤이면 회중전등을 껐다 켰다하면서 울었다”는 이야기로 당시의 소외감을 묘사하고 있다.  그 이후부터는 보스톤에 사는 고모댁과 외조부모댁을 왕복하며 어린 시절을 외로움과 각종 질병에 시달리며 보내야했으며 그의 병약한 체질 때문에 정규 교육 역시 16세가 되어서야 고등학교 입학으로 가능했고 1934년 23세에 Vassar대학을 졸업했다. 이 해에 Bishop과 Marianne Moore와의 만남은 차후 Bishop이 시인의 길을 걷게 되는 중요한 계기가 되었다.  Marianne Moore와의 오랜 교제에도 불구하고 Moore의 시와 Bishop의 시를 비교해보면 서로 상당히 다른 스타일의 시를 썼다는 것은 발견할 수 있으며 이 것은 여러 가지 시사점을 던져준다.   Bishop은 Vassar대학 말기부터 친조부가 물려준 유산 덕으로 불란서, 이태리, 스페인, 모로코 등 여러곳을 여행하기 시작했고 1939년에는 Florida주의 Key West로 이주했으며 1951년부터 1973년까지 약 20여년간 브라질에서 거주하다가 1974년 Boston으로 이주하여 1979년 사망할 때까지 머문다 .    이상의 간단한 이력에서도 나타나듯 Bishop의 삶은 자신의 내면을 탐색하는 여행과 실제 여러 나라의 문화와 사람을 만나며 찾아가는 여행의 연속이었다고 볼 수 있다. 그것은 Bishop의 시 “Sandpiper'에서 묘사되고 있는 무엇인가를 찾아 끊임없이 남쪽으로 해변가를 달리는 sandpiper(도요새의 일종)처럼 가없는 무언가를 추구하며 여행을 다니는 탐색여행자(Quest-traveller)의 모습에 다름 아니다4).    ....  He runs, he runs to the south, finical, awkward,  in state of controlled panic, a student of Blake.  ....  His beak is focussed, he is preoccupied,    looking  for something, something, something.  Poor bird, he is obsessed !

      즉 도요새에 대한 박물학적인 관찰 기록이 아님이 ‘a student of Blake'를 통해서 극명히 드러난다. 도요새가 찾는 것은 모래가 아니라 먹이임이 틀림없지만 무엇인가 열심히 찾고 있다는 점에서 도요새는 탐구하는 이의 상징이며 그러므로 Blake가 얘기한 ’모래 한 알속에 우주가 있다‘는 탐구자의 자세를 보여주는 시인 자신의 모습인 것이다. 그 것은 주어를 관찰자 자신으로 바꾸면 보다 쉽게 드러난다.    ....  She runs, she runs to the south, finical, awkward,  in state of controlled panic, a student of Blake.  ....  Her face is focussed, she is preoccupied,    looking  for something, something, something.  Poor Bishop, she is obsessed !

      Ⅱ    Bishop의 시는 자신에 대한 동정(self-pity)을 애써 피해가지만  여자로써, 그리고 동성애자로서, 고아로서 또한 뿌리없는 여행자로서, 천식으로 평생을 고생해야하는 환자의 입장으로 또 우울증과 알콜중독자의 입장으로서의 느끼는 소외감이 감추어져 있다는 것을 그의 시 전체를 통해서 알 수 있다. Lowell에게 보낸 편지에서도 Bishop의 이러한 자의식들이 다음과 같이 숨김없이 드러나고 있다.   'I'm not interested in big-scale work as such,'   'Something needn't be large to be good.'5)   또한 Bishop이 어린 시절에 겪은 그 절절한 상실감은 그의 시 전체에 걸쳐 깊게 베어있으며 이후 브라질에서 인생의 동반자이자 연인인 Lota de Macedo Soares를 통해 생애처음으로 안정감과 행복을 느끼게 된다. 이러한 안정감과 행복감은 Bishop의 시에서 동물에 대한 묘사와 함께 자폐적인 시야를 벗어나는 계기를 마련해주며 사물에 대한 깊은 사랑, 생명에의 외경, 그리고 존재하는 모든 것들에 대해 있는 그대로의 가치부여 등 시적인 시야의 확대가 이루어지는 것을 알 수 있다6). Soares가 자살 한 후에 다시 미국으로 돌아와서 계속되는 Bishop의 시는 브라질 체류 기간동안의 시적인 세계가 더 성숙되어 가는 기간으로 볼 수 있다. 이런 삶의 변화를 통해 Bishop의 작품세계는 초기 자폐적인 내면탐구와 그 이후 자연과 인간, 그리고 모든 살아있는 현상에 대한 화해와 사랑으로 나눌 수 있지 않을까 한다. 그 이유로 첫째 그의 작품들이 초기에 자신만의 닫힌 세계에서 후기(이 것은 꼭 특정한 시기로 이야기하기는 어렵다)로 오면서 열린 세계로 지향하는 발전성을 보이고 있기 때문이다. 둘째는 그의 작품세계가 대부분 대립관계에서 출발하였고 끝내는 모든 것이 화해를 이루어 출발지로 돌아오는 회귀(recurrence)의 형태를 이루고 있기 때문이다.

      Bishop이 Florida Keywest로 이주하기 이전의 시기가 즉 북부에서 생활하던 시점이 대체로 자폐적 자아탐구 위주의 작품을 쓰던 때로 볼 수 있다. 이 시기는 추정컨대 1935년에서 1938년에 해당되는데 실제로 Bishop이 북부에서 남부의 Florida로 옮겨 살기 시작하던 때가 1937년이기 때문이다. Bishop이 1911년 생임으로 1937년이래야 26세에 불과하지만 작품내용으로 보면 Florida이전과 이후의 작품이 확연히 구별되는 데에서 이러한 구별이 가능하지 않을까 한다.    Travisano의 적절한 지적처럼 Bishop의 초기시는 自閉症的 자아탐구에 머물고 있다. 그렇다고 이 당시에 발표된 작품이 그 수준에서 후기의 시에 비견될 수 없다는 의미는 전혀 아니다. 'The Map', 'The Man-Moth' 등은 오히려 그의 대표작으로 추천되는 상황임을 기억할 필요가 있다. 다만 초기 작품들의 특징은 빙산, 지도, 무덤 조각품 등의 imagery처럼 고정되어있거나 경직되어있든지 혹은 얼어 붙어있고, 오직 활발히 움직이고 있는 것은 그 내면에서 해방을 지속적으로 추구하는 상상력일 뿐이다. 그럼에도 불구하고 그의 초기 작품들이 매우 신선하고 탁월하다는 평가를 받고 있는 이유는 상상력과 관찰의 한계를 보여주는 치밀함과 심지어 치열하다고 까지 말할 수 있는 묘사력과 선명한 이미지, 탄탄한 구성 등에 있다고 할 수 있다.    Bishop의 시를 그의 작품이 보여주는 세계관과 관련하여 굳이  묶어서  구분해야 한다면 북부에서 거주하던 시기에 생산된 작품을 전기시 플로리다 이주 이후에 생산되는 작품을 후기시로 거칠게 구분할 수 있을 것이다. 플로리다 시기 이후는 1937년 플로리다로 이주한 것을 위시하여 그 후 브라질에서의 생활을 포함한 것이다. Bishop의 후기시 즉 플로리다 이주 이후의 시들은 우선 새로운 세계에 대한 다양한 인상기에서부터 자연과 생물, 환경문제에 이르기까지 관심의 영역을 확대하고 있으며 前期詩처럼 자아에만 집중하는 경향도 거의 찾아볼 수 없다. 자아의 문제를 이야기한다 하더라도 “In the Waiting Room'에서처럼 치과치료를 받는 친척의 고통이 곧 나의 고통이 되고 그것은 더 나아가서 고통받는 모든 인간에 대한 따뜻한 눈길과 동정으로 확대되고 있음을 확인 할 수 있다.

      In the Waiting Room

      In Worcester, Massachusetts,  I went with Aunt Consuelo  to keep her dentist's appointment  and sat and waited for her  in the dentist's waiting room.  It was winter. It got dark  early. The waiting room  was full of grown-up people,  arctics and overcoats,  lamps and magazines.  My aunt was inside  what seemed like a long time  and while I waited I read  the National Geographic  (I could read) and carefully  studied the photographs:  the inside of a volcano,  black, and full of ashes;  then it was spilling over  in rivulets of fire.  Osa and Martin Johnson  dressed in riding breeches,  laced boots, and pith helmets.  A dead man slung on a pole  --'Long Pig,' the caption said.  Babies with pointed heads  wound round and round with string;  black, naked women with necks  wound round and round with wire  like the necks of light bulbs.  Their breasts were horrifying.  I read it right straight through.  I was too shy to stop.  And then I looked at the cover:  the yellow margins, the date.  Suddenly, from inside,  came an oh! of pain  --Aunt Consuelo's voice--  not very loud or long.  I wasn't at all surprised;  even then I knew she was  a foolish, timid woman.  I might have been embarrassed,  but wasn't. What took me  completely by surprise  was that it was me:  my voice, in my mouth.  Without thinking at all  I was my foolish aunt,  I--we--were falling, falling,  our eyes glued to the cover  of the National Geographic,  February, 1918.    I said to myself: three days  and you'll be seven years old.  I was saying it to stop  the sensation of falling off  the round, turning world.  into cold, blue-black space.  But I felt: you are an I,  you are an Elizabeth,  you are one of them.  Why should you be one, too?  I scarcely dared to look  to see what it was I was.  I gave a sidelong glance  --I couldn't look any higher--  at shadowy gray knees,  trousers and skirts and boots  and different pairs of hands  lying under the lamps.  I knew that nothing stranger  had ever happened, that nothing  stranger could ever happen.    Why should I be my aunt,  or me, or anyone?  What similarities--  boots, hands, the family voice  I felt in my throat, or even  the National Geographic  and those awful hanging breasts--  held us all together  or made us all just one?  How--I didn't know any  word for it--how 'unlikely'. . .  How had I come to be here,  like them, and overhear  a cry of pain that could have  got loud and worse but hadn't?    The waiting room was bright  and too hot. It was sliding  beneath a big black wave,  another, and another.    Then I was back in it.  The War was on. Outside,  in Worcester, Massachusetts,  were night and slush and cold,  and it was still the fifth  of February, 1918.    메사츄세츠의 워체스트에서  콘수엘로 숙모의 치과 진료에  같이갔다.  그리고 대기실에 앉아서  그녀를 기다렸다.  겨울이어서 일찍 어둑어둑해졌다.  대기실은 방한화와 오버코트를 입은 어른들과  잡지들   그리고 전등으로 가득 차 있었다.  숙모는 진료실 안에서  오랜 시간을 보내는 것 같았다.  기다리는 동안  내셔널 지오그래픽을 읽었다  (나는 읽을 줄 알았다)그리고  조심스럽게 사진을 살펴보았다.  검고 재로 가득찬.  그러다가 불의 시내를 이루며 흘러내리는  화산의 내부를  레이스가 붙은 장화와 토피7)를 쓰고 승마복을 입은 오세이지족과 마틴 존슨을  장대에 매달린 죽은 사람.  ......

      위 시에서 나타내는 어린 시절 시인의 언어에 대한 예민한 감수성과 독서에 대한 흥미 그리고 여인으로 성숙해가는 과정에서 겪는 고뇌에 대해 예리한 관찰을 보여줌으로 minor female Wordsworth라는 상찬을 들을 만한 조숙함을 보여주는 것으로 파악한 Lee Edelman의 비평8)은 시 전체의 맥락을 파악하는데 일견 실패한 것으로 보인다. 사실 Bishop에게 Consuelo라는 이름의 숙모도 없을 뿐만 아니라 1918년대 National Geographic 지에는 Bishop이 언급한 화산에 대한 기사는 다루어지지 않았고 또한 아프리카 원주민에 관한 이야기 역시 마찬가지다. 더불어 이 시에 언급된 문화를 가진 여인들은 아프리카 인이 아니라 인도차이나반도 보다 정확히 미얀마 오지 원주민에 관한 사진과 기록이다. 이 것은 Bishop 본인이 그 오류를 인정한 것처럼 예리한 관찰과 기억에서 창조된 작품이라기 보다는 오히려 Bishop의 초기 시에서 나타나는 자폐적인 경향과 소외와 분리 등에서 벗어나 인간과 인간, 자연과 인간, 생물과 인간들간의 관계를 통해 자신의 존재를 파악하는 시야의 확대선상에 놓여있는 작품이라고 평가되는 것이 더 설득력이 있어 보인다9). 이처럼 동물을 소재로 많은 시를 쓴 후기 시편 중에서 유년기를 소재로 한 “In the waiting room'도 초기 시의 범주에 넣을 것이 아니라 ’ 동물을 소재로 한 많은 후기 시를 보는 관점에서 파악해야 할 것이라고 생각된다.

      전기 시에서는 내면에 세계에서 벗어나지 않아서 잘 드러나지 않던 고통받는 자에 대한 관심은 Bishop의 후기 시편에서 브라질의 빈민, 강도를 포함하여 소외된 인간들에게 보내는 따뜻한 시각으로 나타나며 더 나아가 동물과 인간과의 관계 속에서 자연과 환경, 생물에 대해서도 따뜻한 시각을 보여주고 있다. 여기서 주로 분석할 인간과의 치열한 투쟁 끝에 물위로 끌려올라온 물고기(The Fish)와 인간의 축제 불꽃에 타죽는 아르마딜로(Armadillo)가 바로 그 예일 것이다.  이 것은 시인이 자신의 고통을 극복하고 스스로 만들어 자신을 가두어 두었던 감옥에서 벗어나서 세계를 균형 있는 감각으로 보고자 노력하고 있음을 보여주고 있다.  자아의 자폐적 감옥에서 벗어나 외부의 세계로 보다 성숙한 시선을 향할 때 제일 먼저 사회적인 약자인 여성이나 아동 그리고 동물에게 관심을 가지게 되는 것은 지극히 당연하며 Bishop 역시 예외가 아님을 알 수 있다. 물론 한 사람이 스스로를 자신의 세계 속에 가둔다고 하는 것은 여러 가지 이유가 있겠지만 인간들에게서 당한 고통으로부터 도피하고 싶은 심정을 첫째 이유로 꼽을 수 있다. 그리고 그것이 가장 가까운 이로부터 기인된 고통이라면 그 상처의 깊이와 폭은 상상하기 힘들만큼 커지는 것이다.  상처가 없는 사람이 어디 있을까. 상처가 없는 영혼이 어디 있을까마는 그러한 상흔을 가진 사람으로서  사람보다도 동물에게서 인간의 문제를 발견하고 동물에게서 구원의 가능성을 발견하려는 것은 결코 어색한 현상이 아닐 것이다.    물론 Bishop이 오직 동물만을 작품의 대상으로 삼은 것은 아니다. 폭 넓은 시의 영역과 관심 중에서 동물에 할애하는 부분이 비교적 크고 의미가 있기 때문에 동물과 인간과의 교감을 통해 보여지는  Bishop의 시 세계를 살피는 것이 의미가 있는 작업이라고 판단되었기 때문이다. 후기 시뿐만 아니라 Bishop의 초기 시에서도 동물 이미지를 찾아볼 수 있다. ‘Map'에서도 노르웨이을 달리는 토끼로 묘사한 부분(Norway's hare runs south in agitation, profiles investigate the sea, Where land is. )이라든지, ’The Unbeliever'에서 갈매기가 대기(air)는 대리석 같다 라고 말하며 “Up here/I tower through the sky/ for the marble wings on my tower-top fly'   갈매기의 높이 나는 자만심을 아이러니컬하게도 굳은 탑의 이미지로 나타내고 있는 부분이 그 예다. 후기 시와 초기 시에서 다루어지는 동물에 대한 시각의 차이는 초기 시에 나타나는 동물들의 상은 공통적으로 의인화(personification)한 점을 들 수 있다. 즉 초기 시에 나타나는 동물들은 모두 상징으로서 또는 알레고리로서 표현되고 있는데 첫째 이유는 무엇보다도 이때의 시가 前述한 바와 같이 자아에 집중하고 있으므로 소도구로 등장하는 경우가 많았고 둘째로 동물에 대해 박물학적인 지식을 가진 사실적 접근보다는 상상 속의 Character로 등장하고 있기 때문이다. 그러나 후기 시편에 나타나는 동물들은 The Man Moth에서나  Pink Dog, Rooster, The Fish, Armadillo, The Moose 등에서처럼 주제를 드러나는 굳건한 축으로, 혹은 주인공으로 나타나고 있다. 그 중에서 몇 편의 시에 대해 좀 더 알아보자.

      Ⅲ  The Fish

      I caught a tremendous fish  and held him beside the boat  half out of water, with my hook  fast in a corner of his mouth.  He didn't fight.  He hadn't fought at all.  He hung a grunting weight,  battered and venerable  and homely.  Here and there  his brown skin hung in strips  like ancient wallpaper,  and its pattern of darker brown  was like wallpaper:  shapes like full-blown roses  stained and lost through age.  He was speckled with barnacles,  fine rosettes of lime,  and infested  with tiny white sea-lice,  and underneath two or three  rags of green weed hung down.  While his gills were breathing in  the terrible oxygen  --the frightening gills,  fresh and crisp with blood,  that can cut so badly--  I thought of the coarse white flesh  packed in like feathers,  the big bones and the little bones,  the dramatic reds and blacks  of his shiny entrails,  and the pink swim-bladder  like a big peony.  I looked into his eyes  which were far larger than mine  but shallower, and yellowed,  the irises backed and packed  with tarnished tinfoil  seen through the lenses  of old scratched isinglass.  They shifted a little, but not  to return my stare.  --It was more like the tipping  of an object toward the light.  I admired his sullen face,  the mechanism of his jaw,  and then I saw  that from his lower lip  --if you could call it a lip  grim, wet, and weaponlike,  hung five old pieces of fish-line,  or four and a wire leader  with the swivel still attached,  with all their five big hooks  grown firmly in his mouth.  A green line, frayed at the end  where he broke it, two heavier lines,  and a fine black thread  still crimped from the strain and snap  when it broke and he got away.  Like medals with their ribbons  frayed and wavering,  a five-haired beard of wisdom  trailing from his aching jaw.  I stared and stared  and victory filled up  the little rented boat,  from the pool of bilge  where oil had spread a rainbow  around the rusted engine  to the bailer rusted orange,  the sun-cracked thwarts,  the oarlocks on their strings,  the gunnels--until everything  was rainbow, rainbow, rainbow!  And I let the fish go.    커다란 물고기를 잡았다.  그리곤 그 물고기의 주둥이에 갈고기를 걸어 그의 몸 반쯤은 물위에 나오게 하여  보트 옆에 묶어 놓았다.  그는 저항하지 않았다  아무런 저항도 하지 않았다.  물고기는 지치고 힘든 고색의 보기 흉한 몸을 힘들게 늘어뜨린 채 그렇게 있었다.  그의 갈색껍질은 고대의 벽지처럼 벗겨져 있었고, 진한 갈색 빛의 피부 문양은 벽지 같았다.  오랜 시간이 지난 얼룩지고 옅어진 갈색 장미꽃 모양으로.  따개비들은 검버섯처럼 그의 몸에 둘러 붙어있었고 석회석들은 마치 장미처럼 그의 몸을 장식했다.  작고 하얀 바다벌레들에 시달리며 두 서너겹의 초록빛 바다 풀들을 매단채 그는 그렇게 있었다.    물고기가 그 끔찍한 산소를 들이마실 때 - 그 놀란 아가미, 붉게 핏빛으로 날이 선 그 아가미는 무엇인가를 날카롭게 벨 수도 있을 것 같았다.  나는 깃털처럼 쌓여있는 그 거친 하얀 고기 덩어리들,  크고 작은 뼈들..  그리고 극적으로 빛나는 붉고 검은 내장부위들 그리고 커다란 작약 같은 그 분홍빛 부레를 생각했다.    나는 그의 눈을  나의 그것보다 훨씬 커다란 그러나 더 얇고 노르스름한 그의 눈, 그리고 오래되고 긇혀진 부레풀의 창을 통하여 보여지는 변색된 은박지로 포장된 그의 홍채를 들여다 보았다.  그의 두눈은 조금 움직였다. 그러나 내가 그를 바라봤기 때문은 아니었다. 그 움직임은 차라리 빛을 향한 물질의 가벼운 부딪힘 같았다.  나는 그의 무뚝뚝한 그의 얼굴과 그 턱의 메카니즘에 경탄하였다.  그때 난 그의 아랫입술-입술이라고 부를 수 있다면 말이다.-로 부터험상스럽게 젖은, 마치 무기와 같은 다섯 개의 낚시줄 -혹은 네 개의 낚시줄과 하나의 낚시 연결선인지도 모른다- 그 주둥이에서부터 다섯 개의 커다란 갈고리와 아직도 달려있는 회전고리에 붙어있는 것을 보았다.    그가 망가뜨려 끝이 헤어져있는 초록색 줄과 두 개의 더 굵은 줄들. 그리고 검은 줄은 여전히  그가 벗어나려 할 때 당겨지고 잡아채어져 주름져 있었다.  닳아져 흔들거리는 리본을 단 메달들처럼 다섯 가닥의 지혜의 미늘이 그의 고통스러운 턱으로부터 늘어져 있었다.  나는 그를 뚫어지고 바라보고 또 바라보았다.  그러다 승리의 기운이 녹슨 엔진 주위로 오렌지 빛으로 기름이 흘러퍼져  무지개를 이루며 반사되는 배 밑바닥으로부터  오렌지빛으로 빛으로 녹슬은 파래박에, 태양 빛에 갈라진 좌석들과 줄에 달려 있는 노받이.  그리고 배 가장자리에 이르기까지 온 배 주위에 가득찼다.  모든 것은 무지개, 무지개, 무지개가 되었다  나는 그 물고기를 놓아주었다.

      우선 이 시를 통해 직관적으로 느낄 수 있는 장면은 ‘헤밍웨이’의 노인과 바다의 한 장면과 더 나아가서 모비딕에서 백경을 묘사하는 대목일  것이다. 이 것은 Bishop 자신이 이 시를 Moore에게 보내면서 동봉한 편지에도 이렇게 얘기하고 있다.    “ I am sending you a real 'trifle' ['the Fish']. I󰡑m afraid it is very bad and, if not like Robert Frost, perhaps like Ernest Hemingway!”10)    그리고 ‘The Fish'는 Moore의 성실한 독해와 의견제시에 의해 고쳐지고 다듬어지는 과정도 두 사람이 교환한 서신에 의해 알 수 있다.11) 이 시를 하나의 장면처럼 생각하면서 묘사해보자 ‘작은 배를 가지고 거대한 물고기를 잡아서 뱃전에 달고 온다. 관찰자는 물고기의 겉모습을 보면서 치열했던 생존 방식과 마지막 몸부림도 보고 더 나아가서 물고기의 속까지도 들여다본다. 그리고는 자연의 혹은 신의 창조물과 인간의 창조물인 작은 배의 모습을 비교하다가 그만 고기를 놓아 줘버린다. 그리고 나면 이런 질문이 자연스럽게 나오게 될 것이다. 그처럼 치열하게 싸워서 잡은 물고기를 속속들이 관찰하다가 그만 다시 돌려보내다니!  ’물고기를 잡았다가 놓아주었다고 ? 그래서 어쩌란 말인가? 이런 상식적인 의문은 오히려 자연스러운 반응일 것이다12).    더불어 이처럼 끔찍하게 묘사된 물고기가 실제 존재하는 가13) 아니면 오로지 시인의 풍부한 상상력 속에서 창조된 실재하지 않는 물고기인가 하는 것은 시의 본질과 일견 무관할 수도 있다. 그러나 이 시가 Partisan Review에 발표된 1940년 당시 Bishop은 Florida, Key West에서 실제로 바다 낚시를 즐기고 있었으며 많은 물고기를 접했고 그 물고기에 대해 Moore에게 얘기를 나누었다는 것을 확인할 수 있다14).  이 시에 묘사된 고기의 모습은 난류성 어류이며 고기의 종류가 농어과의 일종인 그루퍼(grouper)라는 것은 어류에 관해 일정한 상식을 가진 이라면 충분히 짐작할 수 있다. 보다 정확하게 얘기하자면 카리브 해와 플로리다 해역에 서식하는 Large red grouper (Epinephelus morio)이며 시 전체에서 묘사된 물고기의 형상과 실제 물고기의 모습은 소름끼치도록 일치함을 알 수 있다.    The Fish에서 Bishop이 그려내는 fish의 이미지는 이처럼 냉철한 객관성을 유지하면서 話者와 fish, 더 범위를 넓힌다면 이 세상에 살아있는 생명체와 우주의 하나됨에 대한 경험을 표현하고 있다. 관찰자는 다만 대상의 정밀한 묘사에만 그치지 않고 자신이 이 거대한 생명체에 대해 느끼는 경외감, 동정심, 두려움, 그리고 그 모든 것에서 파생되는 존경심을 솔직하게 표현하고 있다.   우선 관찰자는 커다란 고기가 붙잡혀있는 상태에서 탈출하려는 시도를 하지 않는 것 혹은 몸부림치지 않는 것에 대해 언급하고 있다. 물론 이 부분도 대형 grouper는 일단 잡히고 나면 그 저항이 별로 강하지 않아서 플로리다 지역과 카리브해 해역의 낚시꾼에게는 별로 인기가 없다는 사실을 Bishop이 잘 알고 있다는 사실 역시 Moore와의 서신에서 이 시에 관해 토론할 때 언급되어 있지만 이런 사실적인 묘사 뒤에 자연의 거대한 창조물이 인간과의 싸움에서 저항하지 않는 다는 것에 관해 근원적인 질문을 던지고 있다는 것을 간과할 수는 없다.    He didn't fight  He hadn't fought at all    물고기는 커다란 몸집을 불편하게 드리운 채(He hung a granting weight) 여기 저기 상흔을 지녔지만 의젓하고 수수한 모습(venerable and homely)으로 비친다. 오래된 피부의 무늬가 낡은 벽지 무늬와 흡사 한 것이며 따개비가 붙어있고 아주 작은 기생충들이 달라붙어 있는 것조차도 놓치지 않고 주목한다. 거칠게 숨을 몰아 쉬는 아가미를 보며 이 생명체를 유지해주는 깃털같이 채워져 있는 근육과 뼈, 심지어는 반짝반짝 빛나는 내장까지도 상상해본다.    관찰자가 역시 생명체인 자신과 물고기의 차이점을 크게 느끼고 있는 것은 눈이다.    I looked into his eyes  which were far large than mine  but shallower, and yellowed.    그러나 ironical하게도 speaker가 물고기와 가장 가까운 친밀감내지 유사성을 발견하는 것은 사람과 물고기 사이에 처절한 싸움이 있었던 흔적이 남아있는 턱을 보았을 때이다.    and then I saw  that from his lower lip  --if you could call it a lip  grim, wet, and weaponlike,  hung five old pieces of fish-line,  or four and a wire leader  with the swivel still attached,  with all their five big hooks  grown firmly in his mouth.    다섯 개의 낚시 바늘은 결국 낚시꾼과 다섯 차례 이상 싸워서 승리했었다는 표창이며 훈장이다.    Like medals with their ribbons  frayed and wavering,  a five-haired beard of wisdom  trailing from his aching jaw.    흔히 말하는 훈장과는 달리 물고기의 훈장은 ‘헤어지고 흔들거리며’(frayed and wavering), 딱 벌어진 가슴이 이나 압도하는 분위기의 용자의 모습이 아니라 ‘고통스러운 턱’(his aching jaw)에 매달려 있는 것이지만 그가 인간들과의 싸움에서 결코 지지 않았다는 점에서 지혜의 수염(beard of wisdom)이 된 것이다. 이처럼 엄청난 물고기를 잡았다는 승리감은 작고 초라한 고깃배 즉 인간의 창조물 혹은 인간 자신의 모습과 날카로운 대조를 이루며 나타난다.    I stared and stared  and victory filled up  the little rented boat,  from the pool of bilge  where oil had spread a rainbow  around the rusted engine  to the bailer rusted orange,  the sun-cracked thwarts,  the oarlocks on their strings,  the gunnels--    이처럼 초라하고 녹슬고 더러운 뱃전의 모습은 speaker가 상상했던 물고기의 ‘반짝거리는 내장’의 모습과도 대조를 이루면서 물고기를 잡았다는 승리감은 퇴색되고 그 대신 생명체에 대한 경외감과 환희로 뒤바뀌면서 결국 물고기를 자유롭게 방생하는 것으로써 새로운 승리감을 맛보게 된다.   그 것은 기름이 엉킨 물들이 무지개 빛으로 번져나가는 환희로 표현되고 있다. 동어반복이 주는 강한 효과를 Bishop은 자신의 시에서 자주 적절하게 사용하는데 특히 이 시에서의 나타나는 효과는 그 어떤 시보다 더 설득력을 주고 있다.    until everything  was rainbow, rainbow, rainbow!  And I let the fish go.

      Ⅳ

      인간은 때론 자아에 대해 혹은 자신을 둘러싼 세상을 객관적으로 보고 깨닫기 위해서는 가까운 곳에서 떠나 멀리 가는 것, 즉 여행이란 것이 필요할 때가 있다.  Bishop은 여행 속에서 많은 작품을 생산한 작가이며 그 중에서도 브라질 여행은 Bishop에게는 시의 영역이나 기법에서도 획기적 변화를 가져온다. 연인을 통해 심리적 안정을 찾은 Bishop은 이제는 더 이상 자신에 대한 연민에 빠져 자아의 울타리를 벗어나지 못하는 자폐증에 빠져있지 않다. 브라질 체류 시기에 생산된 작품을 보면 Bishop은 일상의 사건과 인물 속에서 세계의 모습과 인간의 운명을 객관적으로 때로는 유머스럽게 묘사하며 표출시키고 그 이면에 있는 삶의 신비를 드러내 보인다. 그 대표적인 작품으로서 Armadillo가 있다.

      The Armadillo  For Robert Lowell

      This is the time of year  when almost every night  the frail, illegal fire balloons appear.  Climbing the mountain height,    rising toward a saint  still honored in these parts,  the paper chambers flush and fill with light  that comes and goes, like hearts.    Once up against the sky it's hard  to tell them from the stars--  planets, that is--the tinted ones:  Venus going down, or Mars,    or the pale green one.  With a wind,  they flare and falter, wobble and toss;  but if it's still they steer between  the kite sticks of the Southern Cross,    receding, dwindling, solemnly  and steadily forsaking us,  or, in the downdraft from a peak,  suddenly turning dangerous.    Last night another big one fell.  It splattered like an egg of fire  against the cliff behind the house.  The flame ran down.  We saw the pair    of owls who nest there flying up  and up, their whirling black-and-white  stained bright pink underneath, until  they shrieked up out of sight.    The ancient owls' nest must have burned.  Hastily, all alone,  a glistening armadillo left the scene,  rose-flecked, head down, tail down,    and then a baby rabbit jumped out,  short-eared, to our surprise.  So soft!--a handful of intangible ash  with fixed, ignited eyes.    Too pretty, dreamlike mimicry! O falling fire and piercing cry and panic,  and a weak mailed fist clenched ignorant against the sky!    일년의 이맘때 쯤이면  거의 매일 밤, 유혹에 진 불법적인 불꽃 풍선들이 등장한다.  산만큼이나 높이 기어오르며    이 지방에서는 여전히 영예롭게 일컬어지는 성자를 향해 올라가며  그 종이의 방들은 날아오른다.  그 방들은 마치 심장처럼, 오고가는 빛으로 가득차 있다.    하늘을 향한 한번의 오름으로 그 별들..행성들이다..을 보며 금송이 떨어진다든가, 혹은 화성이나 더 연한 초록색 별이라고 그 변색된 별들을 말하는 것은 어려운 일이다.    바람에 그 불꽃은 타오르다 주춤거리며 비틀거리고 흔들거린다.  그러나 고요할때면 그들은 남십자성의 연대사이로 키를 돌린다.  점점 멀어지고 줄어들며 장엄하고 천천히 우리에게 등돌리기도 하고  그 절정의 순간에 갑자기 하강하며 위험을 연출하기도 한다.    어젯밤 커다란 불하나가 떨어져 집뒤의절벽을 향해 불의 알처럼 흩어졌다.  불꽃이 달려 내려왔다. 우리는 그곳에 둥지를 튼 올빼미들이  위로 위로 날아 오르는 것을 보았다.  그들이 흑백으로 얼룩진 밝은 분홍빛 바닥을 빙빙 돌며 안보이는 곳까지 날아가  날카롭게 울부짖을 때까지    그 고대 올빼미들의 둥지느 다 타버렸을 것이다.  허둥 지둥 완전히 혼자인 반짝이는 아르마딜로가 장미모양의 얼룩이 진채 머리를 또  꼬리를 아래로 하곤 그 무대를 떠난다.    그때 아기 토끼 한 마리가 뛰어나왔다  놀랍게도 짧은 귀를 가진  그 토끼가..  부드럽기도 해라  고정되고 타버린 눈들을 가진 만질 수 없는 한 줌의 재    떨어지는 불꽃과 귀청을 뚫는 외침과 공포  그리고 하늘 향해 무지하게 움켜진  연약한 갑옷의 주목..의 너무나 예쁜  꿈같은 모조품이여.

      이 시는 크게 두 부분으로 나뉘어 있다. ‘This is the time of the year'로 시작하는 첫연에서 ’suddenly turning dangerous'의 제 5연까지가 전반부이고 ‘Last night another big one fell' 의 제 6연에서부터 마지막까지가 후반부이다.   전반부는 축제의 일환으로서 어느 성인에게 띄워 보내는 불꽃 풍선(fire balloons)이 밤하늘을 별처럼 날으며 구경꾼들을 즐겁게 하는 것으로 시작한다. 그러나 ‘the frail illegal fire balloons appear'가 말하듯이 불꽃 풍선을 띄우는 것은 위험한 일로 간주되어 ’불법적‘임을 나타내고 있다. ’illegal' 앞의 ‘frail'이란 형용사는 ’illegal'의 의미를 반감시키면서 축제의 분위기를 강조한다. 설마 저렇게 연약해 보이는 예쁜 꽃풍선이 무슨 해를 끼치랴 하는 선의의 범법자 또는 구경꾼의 심리가 이 한 단어에 잘 나타나 있다.    이 불꽃 풍선은 연약한 인간들의 일상적 소망 -질병으로부터의 보호, 회복, 그 밖에 인간사의 행복을 기원하는 등 의 소원을 기구하는 뜻으로 어느 성인에게 띄우는 오래된 관습임을 알 수 있다. 특히 ‘still honored in these parts' 가 암시하듯 이러한 관습을 적어도 ’문명국‘에서는 보기 어려운 미신적이고 초기 가톨릭이 전파된 이후에 나타난 풍습 임을 넌지시 나타낸다. 하여간 미신이든 아니든 빛을 담아 붉게 물든 종이등은 ’인정(hearts)'을 담은, 극히 인간적인 행사임에 틀림없다.   일단 불꽃 풍선이 하늘에 높이 뜨면 보통 색을 띄고 있는 금성, 화성 등의 행성과 구별하기가 쉽지 않다고 함으로써 이 불꽃축제는 차원 높은 우주의 쇼로 승화하는 듯하다. 하지만 바람이 불면 이들은 ‘flare and falter' 즉 불꽃이 커졌다 작아졌다 이리 저리 밀려다니는 것이 별과 다르기는 하다. 그렇다 하더라도 이들은 높이 날아올라 남십자성 성좌의 연살대 사이로 유유히 항해한다. 하늘의 별자리와 불꽃등의 행렬이 모두 지상의 인간들을 위한 구경꺼리의 일부가 되었다. 그래서 이 불꽃 풍선은 아득히 별처럼 멀어져  receding, dwindling, solemnly  and steadily forsaking us.    인간 속세를 영원히 벗어나는 듯한 착각을 일으키게 한다.  그러나 제 5연의 3-4행은 앞에서 복선으로 심어 놓은 ‘illegal' 'flare'의 단어에서 암시한 바와같이 불꽃풍선이 우주 속으로 아주 사라지는 환상이 아니라 바람이 산 정상에서 아래로 몰아치면  suddenly turning dangerous  대단히 위험한 상황으로 바뀌는 것을 극적으로 나타내고 있다.  불꽃풍선이 집 뒤 절벽에 마치 ‘불의알(egg of fire)'처럼 부딛쳐 불꽃이 폭포처럼 쏟아져 내린 것이다. 그래서 한쌍의 올빼미가 타오르는 불꽃을 피해 달아나고 한 마리의 armadillo가 황급히 고개숙이며 꼬리 내리고 숨는 모습이 눈에 띈다.    Hastily, all alone  a glistening armadillo left the scene  rose-flecked, head down, tail down.    armadillo는 이름이 가리키는 바와 같이 갑옷으로 무장한 개미잡는 동물이다. 불꽃이 가죽에 번들거려 장미꽃잎 같이 붉게 반사하였던 것이다. 시인은 armadillo가 불에 타 죽는 것을 어린 토끼의 불붙은 듯한 공포의 눈으로써 간접적으로 알려준다.    So soft! - a handful of intangible ash  with fixed, ignited eyes.    공중에서 떨어지는 불덩이와 찢어지는 듯한 비명 그리고    and piercing cry and panic,  and a weak mailed fist clenched ignorant against the sky!    갑옷으로 무장한 주먹을 쳐들어 마치 하늘을 향해 항의하는 듯한 자세로 armadillo는 죽어간다. ‘weak mailed fist'와 같은 oxymoron이나 ’clenched ignorant against the sky!'와 같이 전혀 까닭을 모르고 죽어가는 armadillo의 모습은 인간과 자연의 무의식적 투쟁 그리고 거기에 희생되는 수많은 생물의 양상을 소름끼치리만큼 잘 나타내고 있다.  'The Fish'의 잡혀온 물고기도 인간과 싸우는 자연을 대표하며 또 어김없는 희생물이기도 하지만 ‘The Armadillo' 와 다른 점은 초점의 차이이다. 전자에서는 잡혀온 물고기의 세세한 모습에서 심지어는 ’반짝이는‘ 내장의 모양에 이르기까지 전 시야를 다 차지하지만 후자에서는 제 8연 꼬리내리고 머리숙이고 도망가는 모습에서 마지막 연, 주먹쳐들고 비명지르며 죽는 모습만 나타나 있다.   이는 밤하늘에 별처럼 떠서 흐르는 불꽃풍선의 로맨틱한 풍경과도 날카로운 대조를 이루고 있다.   시인은 선명하고도 아이러니칼한 대조를 통하여 국외자의 입장을 끝까지 고수하며 인간과 자연의 충돌을 쳐절하게 그려놓고 있다.  The Armadioolo가 Robert Lowell에게 새로운 전기를 주었다는 일화는 대단히 시사적이다. 이 시가 Robert Lewell에게 헌정된 바와 같이 두 시인 사이에는 상당한 기간동안 서신으로 작품교환이 있었음을 보여준다.  “ 나는 당신의 시를 여러번 읽었습니다. 현재 활동하는 어느 작가보다도 당신의 시를 관심있게 읽었습니다. 틀림없이 개인적 이유가 아니엇더라도 그렇게 읽었을 것입니다. ” 라고 Lowell은 Bishop에게 토로한다. Lowell은 후일에 Bishop의 시 특히 The Armadillo를 읽음으로서 자신의 낡은 스타일에서 벗어나 새로운 형식 즉 ‘Skunk Hour'를 쓰는 계기가 되었다고 솔직하게 고백하고 있다. Travisano는 Bishop의 시가 Lowell 뿐만 아니라 다른 작가들에게도 다음과 같은 의미로써 큰 영향을 주었다고 말한다.  첫째 평이하고 대화체적인 어투로써 노래하듯 표현하면서도 경우에 따라서는 웅변적이고도 긴장감있게 표현한다는 점, 둘째, 상세한 일상생활을 묘사하면서도 커다란 상징적인 의미를 담고있다는 점, 셋째 서서히 전개해 나감으로써 시인이 현장에서 리포트하듯 ‘쓰면서 생각하는’ 방식으로 썼기 때문에 차츰 상징성의 중요성을 부각시키고 있다는 점, 넷째, 일상생활의 상세한 부분을 통하여 숨어있는 신비와 도덕적 양의성(ambiguity) 또는 심리적 긴장의 지하저수지에 도달하고 있다는 점을 들고 있다.

      Ⅴ    Alfred Corn, writing in the 1977 Georgia Review, gives a clear and insightful reading of Geography III that could apply to all Bishop's work. He praises    a perfected transparence of expression, warmth of tone, and a singular blend of sadness and good humor, of pain and acceptance--a radiant patience few people ever achieve and few writers ever successfully render. The poems are works of philosophic beauty and calm, illuminated by that 'laughter in the soul' that belongs to the best part of the comic genius.

      마지막으로 Bishop의 시 한 개를 더 읽어봄으로 이 글을 마친다.  One Art

      Elizabeth Bishop   한 가지 기술

      엘리자베스 Bishop

      The art of losing isn't hard to master;  so many things seem filled with the intent  to be lost that their loss is no disaster.

      Lose something every day. Accept the fluster  of lost door keys, the hour badly spent.  The art of losing isn't hard to master.

      Then practice losing farther, losing faster:  places, and names, and where it was you meant  to travel. None of these will bring disaster.

      I lost my mother's watch. And look! my last, or  next-to-last, of three loved houses went.  The art of losing isn't hard to master.

      I lost two cities, lovely ones. And, vaster,  some realms I owned, two rivers, a continent.  I miss them, but it wasn't a disaster.

      --Even losing you (the joking voice, a gesture  I love) I shan't have lied. It's evident  the art of losing's not too hard to master  though it may look like (Write it!) like disaster.

      잃는 기술을 숙달하긴 어렵지 않다.  많은 것들이 상실의 각오를 하고 있는 듯하니  그것들을 잃는다 하여 재앙은 아니다.

      매일 뭔가 잃도록 하라. 열쇠를 잃거나  시간을 허비해도 그 낭패감을 잘 견디라.  잃는 기술을 숙달하긴 어렵지 않다.

      그리곤 더 많이, 더 빨리 잃는 법을 익히라.  장소든, 이름이든, 여행하려 했던 곳이든  상관없다. 그런 건 아무리 잃어도 재앙이 아니다.

      난 어머니의 시계를 잃었다. 또 보라! 좋아했던  세 집에서 마지막, 아니 마지막이나 같은 집을 잃었다.  잃는 기술을 숙달하기는 어렵지 않다.

      난 아름다운 두 도시를 잃었다. 더 넓게는  내가 소유했던 얼마간의 영토와 두 강과 하나의 대륙을.  그것들이 그립지만 그렇다고 재앙은 아니었다.

      --당신을 잃어도 (그 장난스런 목소리, 멋진  제스쳐) 아니 거짓말은 못할 것 같다. 분명  잃는 기술을 숙달하긴 별로 어렵지 않다  그것이 (고백하라!) 재앙처럼 보이긴 해도.

      그렇다. 다른 모든 것은 다 잃어도 좋다. 허나 사랑하는 사람을 잃는 다는 것은 견딜 수 없는 재앙이다. 그것은 Bishop에게도 그리고 우리에게도 또 나에게도.

      빌라넬(villanelle) 형식의 시. 빌라넬은 처음 5연을 3행, 마지막 연을 4행으로 하고 각 연의 압운을 aba(마지막 연은 abaa)로 하는 정교한 시 형식이다.

      1) A History of Modern Poetry (Modernism and After), David Perkins, Belknap Harvard. 1987. P. 355.

      2) Elizabeth Biship, Thomas J. Travisano, University Press of Virginia. 1988. P. 6.

      3) The Oxford Companion to Women󰡑s Writing in the United States.  1995.  Oxford University Press.

      4) 2000 American Council of Learned Societies. Oxford University Press. P. 54.

      5) The Oxford Companion to Women󰡑s Writing in the United States. 1995 Oxford University Press.

      6) 1953년 7월 28일 그의 시적 동반자인 Lowell에게 보낸 편지를 보면 Bishop이 브라질 생활에서 얼마나 큰 안정과 만족을 느끼는지 알 수 있다. 'I'm extremely happy for the first time in my life' (28 July 1953).'

      7) topee = pith helmet (인도의 헬멧 모자)

      8) From An Enabling Humility: Marianne Moore, Elizabeth Bishop, and the Uses of Tradition. New Brunswick: Rutgers UP, 1990.

      9) The Geography of Gender: Elizabeth Bishop's 'In the Waiting Room.'' Contemporary Literature 26.2 (Summer 1985): 179-196.

      10) Letters of Elizabeth Bishop, Ed. Robert Giroux (New York: Farrar, Straus & Giroux, 1994), 87.  Elizabeth Bishop to Marianne Moore: February 5, 1940

      11) Elizabeth Bishop to Marianne Moore: February 19, 1940  I have been reading and rereading your letter ever since it came … And thank you for the marvelous postcard, and the very helpful comments on 'the Fish.' I did as you suggested about everything except 'breathing in' (if you can remember that), which I decided to leave as it was. 'Lousy' is now 'infested' and 'gunwales(뱃전)' (which I meant to be pronounced 'gunn󰡑ls' ) is 'gunnels,' which is also correct according to the dictionary, and makes it plainer. I left off the outline of capitals [for the first word of each line], too, and feel very ADVANCED.

      12) The conceptual limitations of the poem: the imagery is admirable, but that is not enough (certainly not enough to be worth spending extensive time on); after close examination of ugly old fish, fisherman releases it - so what?  `Some Observations on Elizabeth Bishop󰡑s 󰡐The Fish󰡑Arizona Quarterly 38:4 (Winter 1982)

      13) Integrity of Bishop's fish: it does not seem realistic; it is too ugly; what kind of fish is it supposed to be anyway?  From 'Some Observations on Elizabeth Bishop󰡑s 󰡐The Fish󰡑' Ronald E. McFarland.  Arizona Quarterly 38:4 (Winter 1982)

      14) Elizabeth Bishop to Marianne Moore: January 14, 1939

      The other day I caught a parrot fish, almost by accident. They are ravishing fish  all iridescent, with a silver edge to each scale, and a real bill-like mouth just like turquoise; the eye is very big and wild, and the eyeball is turquoise too ? they are very humorous-looking fish. A man on the dock immediately scraped off three scales, then threw him back; he was sure it wouldn󰡑t hurt him. I󰡑m enclosing one [scale], if I can find it. …",

      '电影特别是纪录片的客观性与主观性问题，长期以来一直是电影理论界争论的焦点之一。经过整整一代解构主义电影理论思潮的反复拆解，电影研究者们逐渐趋向于认为影像的客观性是一个“伪命题”。一个常被引用的例子是美国汇编纪录片导演埃米尔·德·安东尼奥的作品《猪年》，它的素材几乎全部取自影像资料，其中大部分是美国政府军方拍摄和新闻电视频道播送的越战宣传纪录片。但它仅仅依靠资料选择和剪辑就扭转了这些影像的涵义实现了强烈的反战意识形态表达。许多人都认为这样的纪录片彻底颠覆了影像的客观性，它被主导影片的意识形态所完全摧毁。

      德勒兹电影理论对此有着截然不同的观点。首先，依托于柏格森的运动理论，德勒兹认为“电影无法重构真实的运动而只是运动的幻象”的说法虽然并不能完全被否认，但该论断只涉及了电影影像所呈现的内容。而站在影像本体的高度来看，尽管电影构筑影像－运动的手段是人工化的，但是影像－运动本身是真实完美的运动。以银幕为媒介的影像－运动所呈现的与现实相关的内容可能失去了其真实性，但是影像－运动本身却是世界最真实的呈现，它的客观性正是电影的本质特征之一。以此为出发点，在影像－感知（影像－运动的三个类型之一）的范畴内，德勒兹重建了客观与主观的概念。他认为它们是影像－感知的两极，或者说是感知世界的两种方式。组成一部影片的客观影像具有普遍互动性，即所有的影像之间具有一种平等性，它们以自身为中心同时又与其他影像互相影响而产生互动，处在一种共同变化演进的过程中。而主观影像是另一种影像的组织方式，它失去了自身的独立地位，而以某一个被确认的影像为中心点，其他影像围绕着这个影像而产生联动变化的关系。为了进一步说它们的特性，德勒兹借用了物理学和化学的概念——他认为影像的客观性是“液态”，而影像的主观性是“固态”。液态影像是几乎完全自由的可以容纳一切，它多样化，具有非稳定状态和多重性，可以呈现瞬间的反应。液态影像之间的联动正如向水中投入一颗石子，水波和所反射的影像会成倍叠加，互相促进并把运动传播下去。而固态影像则有如一张稳固的桌子，它有确定的着力点（中心点）以保持平衡，当我们向桌面投掷一个石子，它会向一个确定的方向反弹。这是主观影像给观察者的一个固定不变甚至可以预计的运动方式。

      从这个角度看，一部分的实验电影和纪录片——德勒兹列举了伊文思的《雨》和《桥》，维尔托夫的《持摄影机的人》和鲁特曼的《柏林：城市交响曲》——都符合液态影像的特征：组成影片的各个元素都以自身为中心进行互相关联的运动和变化。德勒兹对《桥》进行了详尽的分析：他引用柏格森的观点，认为感知如果开始利用某个客体，它即产生了功能或者为某个特定的目的而服务。而具有客观性的物体是不为任何事物服务的，这恰恰是伊文思的《桥》为观众所带来的：处于影像普遍互动系统中的桥，我们不再注重它的功能，它的实用性被消解，我们看到的是一个在“液态”状态下被全面呈现的桥的影像。另一方面，固态则构筑了另一类型的影像：组成它们的元素始终围绕着事先人为设定的一个中心点运行。这就是我们所熟悉的由好莱坞所创造和发展的一整套剧情故事片创作原则——影像不再平等和独立，而是为创作者所确定的某一个中心内容所服务。衡量影像的标准则是看以这个中心为基点各个元素之间的互动是否形成了其整体性。

      如果我们借助德勒兹对客观与主观的定义再审视《猪年》，便会一目了然。就这部影片来说，影像的客观性不来源于其内容本身，它们做为原始材料的性质是混沌的。客观与主观产生于组织材料的方式，即“影像－感知”的方式。当埃米尔·德·安东尼奥把握着强烈预设的反战政治意识形态对这些影像材料进行“感知化”组合的时候，影像无疑在此时凝结成了“固态”，围绕着导演设置的思想中心点进行了重构。这部作品的影像必然带有确之凿凿的主观性。但这种主观性并不能否认影像客观性的存在，特别是当我们看到如伊文思的《雨》或者鲁特曼的《柏林：城市交响曲》这样纪录性作品时，影像之间自由而平等的组织方式让它们产生的“客观性”感知不容置疑。

      更进一步，德勒兹还认为，客观影像与主观影像之间并不是一成不变。在一部影片中两者可能不断地从一极滑向另一极，正如物质世界中的固体和液体在一定的物理和化学条件下可以互相转换一样。这样的主客观变化过程我们可以在很多欧洲电影大师的作品中见到，德勒兹曾经详细分析了他所推崇的法国导演格雷米永在他的影片《拖船》中如何利用客观与主观之间的转换——表现为主角的日常职业生活和突如其来的爱情之间的剧烈反差冲突——来支撑起一部电影作品的实质内核；相同的手法在安东尼奥尼的名作《蚀》里被同样使用：由开场对股票市场运作大段冷静克制的观察过渡到主人公内心的空寂，同样是由客观过渡到主观所形成的反差魅力；而费里尼则在《甜蜜的生活》中则把普遍互动（人物在城市中的游走）和确定中心（主角浸满空虚的哀伤情绪）交织一起。电影理论史上，曾经有各种不同的方式来描述好莱坞电影与欧洲电影的差别，德勒兹的客观／主观影像给了这个问题一个新的视角：好莱坞电影自始至终都是主观影像，而欧洲电影则或多或少都游离在客观与主观两极之间，所刻画的就是两者互相转换的过程。

      现在当我们回顾德勒兹的客观／主观系统，会发现它们不再是通常理解意的个人／非个人化的视角，而是两种不同的影像组织和运动模式，它们在整体上与影像－运动的概念紧紧扣合在一起。

      回顾历史，虽然纪录片拥有和剧情片一样长的发展历程，但纪录片理论却一直远远落后于以剧情片研究为主的一般电影理论。直到1980年代中期，美国纪录片理论家迈克·雷诺夫（Michael Renov）还在文章中感叹：“放眼电影研究的各个领域，纪录片是最少被人讨论的。” [2]相较于剧情片，纪录片受众面更小，关注度更低，这种情况似乎也不是不正常。但不能忽视的是，这种状况的出现与长久以来学界的某些偏见不无关系。比如法国电影理论家麦茨（Christian Metz）就曾明确提出，纪录片不具备区别于剧情片的独特的表意形式，和剧情片一样，纪录片的表达也离不开虚构。“一切影片都是剧情片” [3] ，纪录片当然也不能例外。对于纪录片研究来说，这一论断当然不是没有相应的理论意义。但对于当时的纪录片理论发展来说，它却成了一盆浇头冷水，因为它从根本上动摇了当时人们所理解的纪录片存在的前提，威胁到了纪录片的身份合法性。如果所有电影都是虚构的，那么被称为非虚构电影的纪录片是个什么东西呢？它的处境变得相当尴尬。一直到1990年代初，这种对纪录片理论的轻视和怀疑才有了根本的改变。

      1990年11月，俄亥俄大学（Ohio University）电影系照例举行了自己的年度研讨会。与以往不同的是，这一年的主题确定为纪录片研究。由于当时这种以纪录片为主题的研讨会并不多见，纪录片学者们都非常珍惜，重要人物悉数到场。站在今天来看，这是西方纪录片理论发展史上一次非常重要的集结。会议上宣读的若干文章发表在了重要期刊《广角》（Wide Angle）的研讨会专刊上，另外一部分文章被收录于雷诺夫主编的《理论化纪录片》（Theorizing Documentary，1993）一书中。[4]更为重要的是，当时的与会者普遍感觉这样的研讨非常重要，纪录片研究者应该有自己定期的学术会议。于是经过一段时间的酝酿，第一届“可见的证据”（Visible Evidence）纪录片研讨会于1993年9月移师杜克大学（Duke University）召开。在此后的20年间，这个聚焦于“纪录片的策略与实践”的研讨会每年都会举办一届。伴随着纪录片创作的狂飙突进和纪录片理论研究的不断升温，如今“可见的证据”已经成为世界范围内最重要的纪录片学术盛会。以这一会议为依托，一套同名的纪录片理论丛书也在不定期出版。截止2012年，这套书已经出版了28本。[5]        虽然影响巨大，但“可见的证据”研讨会自始至终没有任何正式的组织机构。它的几位主要的发起人比尔·尼科尔斯（Bill Nichols）、迈克·雷诺夫、布莱恩·温斯顿（Brian Winston）等，都是当代纪录片学界重镇。他们个人在1990年代一系列的重要著述奠定了当代纪录片理论研究的基础，推动纪录片研究成为当代电影研究、媒介研究中，最受瞩目的领域之一。这其中包括尼科尔斯“突破性的” [6]《表现现实》（Representing Reality,1991）和《模糊的边界》（Blurred Boundaries,1994）、雷诺夫主编的《理论化纪录片》以及温斯顿那本被称为“英语世界第一部理论化阐述的纪录片史” [7]的《以真实的名义》（Claiming the Real,1995）等。此外，约翰·康纳（John Corner）的《纪录的艺术》（The Art of Record,1996）、卡尔·普兰廷加（Carl Plantinga）的《非虚构电影的修辞与表达》（Rhetoric and Representation in Nonfiction Film,1997）也是这一时期重要的著作。

      如果把1980年代后期《谢尔曼的长征》（Sherman’s March,1986）、《细蓝线》（The Thin Blue Line,1988）、《罗杰和我》（Roger and Me,1989）等作品的出现视作一个新时代的开始，那么经过1990年代的发展，2000年之后我们才真正目睹了纪录片在世界范围内的全面勃兴。与此类似，纪录片理论研究经过了80、90年代的筚路蓝缕，此时也转入了快车道。前面曾提到，很长时间以来，纪录片研究在电影研究、媒介研究中通常只能忝陪末座，但此时却俨然成了一门显学。过去极少刊登纪录片文章的学术期刊，开始大量出现纪录片稿件。2007年出现了第一本英语纪录片理论期刊《纪录片研究》（Studies in Documentary Film）。在2000年之前，一般是一年或几年才出一本纪录片专著，现在每年都面世若干。除了尼科尔斯、雷诺夫、温斯顿等相继出版了新的理论著作，更多学者开始在纪录片研究领域发力。如斯泰拉·布鲁兹（Stella Bruzzi）、乔纳森·克海纳（Jonathan Kahana）、伊丽莎白·考伊（Elizabeth Cowie）、约翰·埃利斯（John Ellis）等学者都相继推出了自己的纪录片专著。[8]纪录片研究的深度、广度都有了极大的拓展。值得一提的是，在中国纪录片研究方面，也有若干文集、专著面世，如《从地下到独立》（From Underground to Independent,2006）、《中国新纪录运动》（The New Chinese Documentary Film Movement,2011）、《独立的中国纪录片》（Independent Chinese Documentary,2013）等。[9]2011年，著名电影季刊《电影人》（Cineaste）的一篇编者按说：“美国过去十年间出版的纪录片著作可能已经超过了此前五十年的总和。” [10] 这并非夸张。英国学者迈克·哈南（Michael Chanan）曾经就此评论说，最近几年纪录片研究领域所发生的一切不啻为一场“突然的爆炸”。

      以上是对近年来西方纪录片理论研究发展历程的一种粗略描述，下面笔者对这一时期若干核心理论议题展开具体讨论。其中包括纪录片的形式问题、纪录片的功能问题、纪录片作为科学证据的问题、纪录片的真实性、客观性问题，纪录片的定义问题等五个方面。总体上说，这些议题从不同侧面构成了纪录片理论的一个核心追问，即纪录片究竟是什么的问题。从理论策略上说，这些探索也不约而同地构成了对长久以来一直占据统治地位的直接电影的理论反思。

      此外还需要说明的是，本文讨论的是后直接电影时期的纪录片理论，但熟悉西方纪录片理论的人都知道，西方既有理论论述中并没有“后直接电影”这一专门术语，以后直接电影概念来对纪录片史进行分期更非学界公认。这一点希望不会对读者造成误导。在后文第四部分，笔者还会对此做进一步的说明。

      1、纪录片的形式问题

      在纪录片史上，作品的形式、风格并不总是像今天这样为人们所重视。在很多时候，纪录片的美学追求甚至被刻意贬低。比如，“纪录片之父”约翰·格里尔逊（John Grierson）就曾出于种种现实考虑，反复强调自己反美学的立场：“纪录片从一开始就是……一场反美学运动”。 [12]经过了1960年代直接电影、真实电影的洗礼，到了1970年代这种倾向不降反升。比如美国学者亨利·布雷特斯（Henry Breitrose）就曾在1975年写道：  技巧与风格是有用的，也是重要的，但影片所能带给一名观众的兴奋不会高过当他看到未经剪辑的工作样片或未经处理的档案素材时产生的那种兴奋。驱动纪录片导演的是内容美学。对于观众来说，只要内容有趣，那就是好作品了。这是一个颠扑不破的原则。[13]  这种对形式的贬低并非偶然，其中隐含的是直接电影那种把镜头呈现的内容等同于现实的认识论假定。虽然在电影研究领域早有人对安德烈·巴赞（Andre Bazin）和齐格弗里德·克拉考尔（Siegfried Kracauer）的现实主义理论进行了反思，但明显的是这种反思并没有渗透到纪录片研究领域。在纪录片界，人们依然相信银幕就仿佛是通向世界的窗户。通过这扇窗，人们看到的就是真实的现实世界。这是一种被某些理论家称为“幼稚现实主义”的观点。 [14]      尼科尔斯或许是最早看到这其中可能存在意识形态陷阱的理论家。他的解决思路是以文本分析的方式来打破影片营造的现实的幻觉：  只有通过考察一系列声音、画面如何表情达意，我们才能把纪录片从那种将影片等同于现实，把银幕视作一扇窗，而不是一个反射的平面的反理论的、意识形态上沆瀣一气的观点中解救出来。 [15]  从这个基本判断出发，尼科尔斯开始了自己对纪录片形式的研究。在此后的30余年里，几经调整、扩充、修正，最终建立起目前学界最具影响力的纪录片类型学理论。

      从《纪录片理论与实践》（Documentary Theory and Practice,1976）到《纪录片的声音》（The Voice of Documentary, 1983）[16] ，再到《表现现实》，尼科尔斯将纪录片划分为四种类型，即解释型、观察型、互动型和自我反射型。这四种类型每种类型都包含着不同的形式特征和意识形态含义。解释型纪录片的典型代表是格里尔逊式纪录片，片中画外解说地位突出，有时具有强烈的说教色彩。画面的安排不追求时空的连贯，而采用了“证据剪辑”（evidentiary editing）[17]的方式，即画面服从于解说，解释、说明、印证解说词。中国传统的专题片采用的正是这样一种形式。

      观察型纪录片主要指的是直接电影（direct cinema），其典型作品如德鲁（Robert Drew）小组拍摄的《党内初选》(Primary,1960)、弗莱德里克·怀斯曼（Frederick Wiseman）的系列作品等。这种表现方式的技术基础是二战期间发展起来的便携式摄影机和可以同步拾音的磁带录音机。这一类型的纪录片隐匿影片创作者的存在，排斥画外解说，充分运用运动长镜头、同步录音、连贯剪辑等技术手段，以一种透明的、无中介的风格，试图对现实事件进行完整的复制。这种类型的纪录片相信客观世界里真实的存在，相信只要观察得足够细致，就可以捕捉到真实。中国1990年代新纪录片所主张的正是这样一种美学。典型作品如张元、段锦川的《广场》(1994)、段锦川的《八廓南街16号》（1997）等。

      互动型纪录片对应于我们通常所说的真实电影（cinema verite），其典型作品如《夏日纪事》(Chronicle of a Summer,1960)等。在这种类型的影片里，影片创作者作为社会角色之一，主动地介入事件，展开采访或搜集信息，与其他社会角色互动。它采用和观察型纪录片相类似的技术手段，如同期声、长镜头等，完整捕捉镜头前影片创作者与他人的互动过程。与观察型纪录片不同，它不追求绝对的、未受干预的真实。它所强调的是影片创作者介入事件后，“撞击产生的真实”。 [18]采访和口述是参与型纪录片的重要标志。在《纪录片的声音》一文中，这一类型又被称作是“采访引导”或者“基于采访”的影片类型。 [19]中国新纪录片的开山之作《望长城》（1991）就是这样的代表。

      自我反射型纪录片将影片关注的重心从被拍摄对象转向了影片创作过程本身，拍摄行为和影片本身成了反思的对象。这种表现方式持有一种怀疑主义的认识论。它质疑现实主义的表现手段，也质疑媒介机构或影片本身的解释能力。这种表现方式促使观众重新审视影片本身的媒介属性和构成方式，从而令观众对影片建立起更高层次的理解和期待。中国导演雎安奇的《北京的风很大》(1999)可以归属于这一类型。

      1990年代初，新纪录片日渐兴起，纪录片的形式、风格更加丰富多样。这促使尼科尔斯在上述四种类型之后，在《模糊的边界》（1994）一书中又概括出一种新的纪录片类型，即表述行为型纪录片。这种类型纪录片最重要的一个特征是它放弃了纪实风格，强化了对于创作主体的主观体验、主观感受的传达，相信个体的主观体验是我们把握世界的可靠途径。主观镜头、印象式蒙太奇、戏剧化的灯光、煽情的音乐等等一些表现主义的元素在这里都派上了用场。 [20]中国导演张以庆的《英和白》(2001)、刘德东的《落地窗》（2012）都可算是这一类型的典例。

      在接受了卡尔·普兰廷加等人的批评和迈克·雷诺夫等人的提醒之后，到了2001年，尼科尔斯再次修正了自己的分类理论。 [21]在第一版《纪录片导论》（Introduction to Documentary,2001）中，尼克尔斯新增了诗意型纪录片，并将互动型纪录片改称为参与型纪录片。按照尼科尔斯的解释，诗意型纪录片最早出现于1920年代，典型的作品如尤里斯·伊文思（Joris Ivens）的《桥》（The Bridge,1928）、《雨》(Rain,1929)等。诗意型纪录片的出现与当时先锋派艺术相关，其表现方式偏爱“片段拼贴、主观印象、不连贯的动作和松散的连接。” [22]它强调的是情绪、气氛，而不追求叙事或劝服。中国导演黄伟凯的《现实是过去的未来》（2008）、张以庆的《听禅》（2011）都属于这种类型。

      这六种纪录片类型是纪录片家族中的六个核心分支，对于纪录片形式研究来说，它们提供了一个基本的思考框架。在西方纪录片学界，尼科尔斯的分类理论被人们广泛讨论和接受，但是也有很多人对其持怀疑、否定的态度。比如斯泰拉·布鲁兹在自己专著的序言中就对尼科尔斯的理论进行了猛烈抨击，称其所呈现的是一种“达尔文主义式的纪录片史” [23]。­­­­自从《纪录片的声音》、《纪录片导论》译介到中文领域以后，包括一些译者在内的很多中国学者都认为尼科尔斯的分类理论所提供的是一种版本的纪录片史。这些都是错误的理解。此外值得我们注意的是，很多中外学者在对尼科尔斯分类理论进行阐述时，都有含混、错误之处。比如《纪录片百科全书》（Encyclopedia of the Documentary Film, 2006）中，有论者把自我反射型纪录片与表述行为型纪录片混为一谈。 [24]再比如较早译介到中文的《纪录恐惧症与混合模式》（Documentaphobia and Mixed Modes, 1998）一文，作者试图以尼科尔斯的理论对影片《罗杰和我》进行文本分析，其中错误就更多。 [25]      或许是为了回避布鲁兹等人的指责，在第二版《纪录片导论》（2010）中，尼科尔斯撤掉了第一版中描述纪录片形式演进的图示，但补充了之前未曾详细论述过的其他媒介中存在的非虚构模型（nonfiction model），如新闻调查、人类学调查、民族志写作、历史写作等。它们与不同形式的纪录片表达构成了某种对应。如此一来，尼科尔斯就为纪录片的形式研究提供了不同于原来的“类型”（mode）的第二个范式。[26]这是一段富有启发的阐述，尽管极其简略。当然在纪录片实践中，这样的实例从来不鲜见。比如我们身边的一位独立纪录片导演徐童，他的作品《算命》（2009）就成功地借鉴了中国传统章回体小说的结构、风格。但尼科尔斯这里是将非虚构模型作为纪录片形式研究的一般方法论提出来，值得格外关注。

      2、纪录片的功能问题

      对纪录片形式的分析使尼科尔斯更清晰地把握到纪录片表达中所存在主观操纵。他在1986年撰文指出，纪录片并非对现实世界的客观纪录，而是运作于“实际的生活和被讲述的生活之间的交叠处” [27] 。迈克·雷诺夫对纪录片概念的理解与此非常相似。在1990年俄亥俄大学的研讨会上，雷诺夫指出纪录片和任何诗学表达一样，处在“科学与美学、结构与价值、真与美的接合处”。 [28] 从这一基本判断出发，雷诺夫提出了建设“纪录片诗学”（poetics of documentary）的设想。按照亚里士多德（Aristotle）的论述，诗学既研究诗歌的一般构成原则，也要研究其功能和效果。 [29] 如果说尼科尔斯的纪录片类型学更侧重于前者的话，那么雷诺夫则将关注的重心放在了纪录片的功能上。

      从纪录片创作者的动机出发，雷诺夫将纪录片的功能分为四种：记录、揭示或留存，劝服或推广，分析或质询，表现。和许多人一样，雷诺夫也承认记录现实是纪录片最基本的功能，但他论述的重点还是质疑长久以来被普遍接受的摄影影像所具有的真实性、客观性。和尼科尔斯一样，雷诺夫认为纪实影像不过是一种对现实的表现符号，一种能指，不可错误地将其与现实划等号。而且对于纪录片表达来说，获得符号的过程本身充满了创作者的主观干预。“我们试图将摄影机前的现实‘固定’到胶片上的努力……如果不是虚伪的话，也是非常脆弱的。” [30]借用罗兰·巴特（Roland Barthes）对历史话语的批评，雷诺夫提出纪录片所营造的客观性实际上不过是一种特定形式的虚构。

      格里尔逊曾经主张银幕是一个讲坛，而影片则是改造社会的锤子。此时第二种功能即劝服功能主导了整部影片。但雷诺夫强调，“劝服或推广形态内在于所有纪录片形式” [31]，任何一部纪录片都包含着一定的个人目的或社会目的，都需要运用相应的修辞手段，实现其劝服的功能。雷诺夫所说的第三种功能是分析或质询功能。在他看来，这种功能主要体现为对纪录片记录、揭示、留存功能的一种反思。由此看来，这一功能与尼科尔斯讨论的自我反射型纪录片具有很多的关联。

      在所有纪录片类型中，尼科尔斯认为“最有前途的” [32]是自我反射型纪录片，而雷诺夫则对强调主观表现的纪录片类型最为看好。针对当时的创作实践，雷诺夫认为纪录片的表现功能被人们严重低估了。他认为从追求复制现实的直接电影到高度表现主义的作品之间是一个连贯的谱系，主观表现之于纪录片表达不是有和无的问题，而是一个程度大或小问题。很显然，从策略上说，雷诺夫这是在为纪录片中的主观表现正名。

      雷诺夫的判断显然是准确的。在此文之后20多年的时间里，人们没有见到尼科尔斯所期望的自我反射型纪录片的复兴，却共同目睹了表述行为型纪录片、第一人称纪录片、动画纪录片等亚类型的蓬勃崛起。它们共同的特征是抛开表面的客观性原则，调用更多可能的手段强化对创作者的主观经验、主观感受的表现。雷诺夫对这些作品始终保持着密切的关注，并称其为近年来“纪录片领域最持久的成果” [33]。实际上在过去的十几年间，雷诺夫的学术研究基本上是围绕着纪录片的主体性问题展开的。特别对于第一人称纪录片中的自传体纪录片，雷诺夫尤其关注。在他看来，这一纪录片亚类型已经重塑（reinvent）了人们对纪录片的认识。[34]

      雷诺夫对纪录片功能的阐述是从创作者的角度出发而展开的，另一位英国学者约翰·康纳则从纪录片与社会之间的关系入手，对纪录片的功能进行了另外的分类。 [35]和大多数英国学者一样，康纳更多地以电视纪录片为参照展开自己的研究。这与尼科尔斯、雷诺夫等美国学者偏重纪录电影、特别是独立纪录电影的做法有明显不同。

      康纳总结的第一种功能类型是那种作为官方机构的工具，对公民进行说服教育的纪录片。这当然是格里尔逊在1930年代留下的最大遗产。这种影片高度依赖解说，但也注重音乐和其他声画修辞手段的运用。第二种类型是作为新闻报道的纪录片，即那种由出镜报道、画外解说以及采访构成的纪录片作品。第三种类型是非官方制作的激进的或阐释异见的纪录片。这种类型的纪录片既不接受官方立场，也不追求新闻报道标榜的客观、公正。其目的在于修正人们对某些政治问题、社会问题的习惯见解。

      这三种纪录片功能类型都有长久的历史和传统，与电视的关联也不那么紧密。但被康纳称为“作为娱乐的纪录片”的第四种类型则有所不同。按照康纳的观点，这种纪录片很大程度可以被视作是电视机构市场策略的产物。随着电视产业的发展，出于娱乐受众、提高收视率的目的，许多电视节目，如纪实肥皂剧、电视真人秀等，纷纷借用纪录片的形式元素，使得我们难以辨清其与纪录片的边界。另外，就纪录片创作本身来说，它也开始越来越多地采用表演的元素。传统的社会、历史等宏大主题发生改变，严肃的风格也不再是唯一的选择。很多时候纪录片已经不再是尼克尔斯所说的“严肃话语”，而成为了娱乐受众的节目形态之一。康纳甚至因此断言，此时我们已经进入了一个“后纪录片” (post-documentary )的时代。[36]

      3、纪录片作为科学证据的问题

      如前文所述，尼科尔斯确认了纪录片六种不同的表达形式，观察式纪录片不过是其中一种。雷诺夫总结了纪录片四种不同的功能，那么对现实世界进行记录也就只算是纪录片基本功能之一了。这些论述固然是对纪录片本体理论的重要发展并成为其核心组成部分，但从策略上说，这样的主张也共同构成了“后直接电影”时期理论界对直接电影美学的反动和颠覆。

      1960年代初，伴随着新技术的发展，直接电影在北美跃世而出。直接电影导演主张纪录片“不过就是人们窥视现实的一扇窗” [37]，摄影机唯一的权力是“记录发生的事件” [38]。从这一极端立场出发，任何不同于直接电影的纪录片表达都变得十分可疑。直接电影领军人物罗伯特·德鲁（Robert Drew）就曾直言：“在我看来，除了个别例外，总体说来（除了直接电影）纪录片都是假的。”[39] 一些评论家敏锐地发现了直接电影的这种排他性。如詹姆斯·布鲁（James Blue）就曾指出：“直接电影有了正统与异端之别，有了自己一神论信奉者和原教旨主义者”[40] 。直接电影俨然成了某种类似“现代宗教”[41]一样的东西，只有奉行直接电影美学才可以被称之为纪录片，任何其他类型、手法、风格都不具备合法性。不难看出，这种激进的主张多么容易蜕变成对纪录片表达的禁锢。历史事实也的确如此。直到1980年代末期，西方纪录片创作才彻底打破直接电影的束缚，开始了多样化发展的时期。就此时的纪录片理论工作来说，首先要做的就是对直接电影美学进行恰当、合理的解释。这是“后直接电影”时期纪录片理论发展的历史要求。实际上，要完整、准确地理解这一时期的纪录片理论，对这一特定历史语境是不能忽视的。否则就可能出现偏差，甚至像诺埃尔·卡罗尔（Noel Carroll）、卡尔·普兰廷加一样，对尼科尔斯、雷诺夫和温斯顿等人做出偏激的指责。 [42]      如果我们也像雷诺夫一样，把纪录片理解为科学与美学的交叠的话，那么可以说前面尼科尔斯和雷诺夫的理论阐述是沿美学维度展开的。与此同时，温斯顿则一方面通过细致的历史考察，揭示直接电影实践者本身的自相矛盾，另一方面对纪录片特别是直接电影何以获得了科学性地位进行了深入剖析。在1993年文章《纪录片作为科学刻写》（Documentary Film as Scientific Inscription）和1995年的专著《以真实的名义》（Claiming the Real）中，温斯顿首先提醒我们注意到，摄影机最初是作为一种科学工具而被公众所认识和接受的。摄影术的主要鼓吹者亚拉贡（Arago）为了争取法国政府的支持，避免画家群体的反对，处心积虑地将摄影机与温度计、气压计、显微镜并置一处，突出强调了其作为科学研究工具的身份。这种强调的大背景是现代科学对科学实验的重视和对科学仪器的高度依赖。人们相信科学仪器能够克服观察者本身的主观性，因为只要方法得当，通过仪器的使用不同的人会获取同样的科学数据。温斯顿指出，纪录片之所以可以作为证据而存在，其合法性最重要的来源就是摄影机的这种“科学性关联” [43]，而以“墙壁上的苍蝇”为口号的直接电影则把这种科学至上主义色彩的修辞发挥到了极致。 [44]      按照直接电影的说法，创作者的主观干预应该被完全摒弃，摄影机是科学考察的工具，其功能不过是搜集和呈现客观的事实和证据。当然，由于直接电影创作中，创作者的主观介入和对内容的阐释随处可见，直接电影的这些主张根本无法自圆其说。实际上，直接电影对客观性、真实性的高度强调恰恰成了人们质疑直接电影本身的最好的理由。身兼哲学家和电影学者双重身份的诺埃尔·卡洛尔对此曾做过一个生动的比喻：“直接电影打开了装满蠕虫的盒子，然后被蠕虫给吃掉了。” [45]      除了一直以来将摄影机视作科学工具的倾向，温斯顿还提醒我们注意到格里尔逊和直接电影所主张的纪录片真实性的另外一个基础，即1930年代以来，科学研究领域中概率理论的发展。在19世纪以前，科学家们相信主导这个世界运行的是牛顿式的因果律和必然性。但从19世纪初到1930年之间，人们逐渐认识到或然性的重要。“1930年后不久，几乎可以确定的是实际上主宰我们世界的至多是或然律。” [46]著名导演埃罗尔·莫里斯曾经的导师、科学哲学家托马斯·库恩（Thomas Cohen）称这是一种科学范式的转变，或可被称之为“革命”。 [47]1930年代正是格里尔逊全力推动其英国纪录片运动的时期，在上述科学范式转变的背景下，对于纪录片表达来说，“一次捕鱼就是鲱鱼业，一列火车就是夜间邮政系统” [48]（指格里尔逊团队创作的两部纪录片作品《漂网渔船》和《夜邮》）。温斯顿总结道：  隐含的或然性概念使得对某一事件或某个人的特定描述可以被扩展成为对此一事件或个人所属总体的一种说明，只要这种描述还可以体现出一定的社会意义。或然性通向了举隅法，而举隅法则成了纪录片“真实性”的关键。 [49]  这种以局部指代总体的做法很多时候都体现在纪录片作品的名字上。比如弗雷德里克·怀斯曼（Frederick Wiseman）将自己的一部作品称为《高中》（High School），而并没有叫做“导演怀斯曼和他的摄影师于1968年3、4月间在费城的东北高中所拍摄的见闻”。在温斯顿看来，只要纪录片还在主张对社会议题的关怀，这种潜在的转换就必然存在。同时，由于影片这种概括性的名字掩盖了创作者个体的中介与干涉，它也暗中强化了影片对客观性、真实性的主张。

      4、纪录片的真实性、客观性问题

      尼科尔斯对文本构成形式的分析提醒我们注意到，在纪录片表达中，意识形态始终在场。温斯顿则通过对科学史的考察，向我们揭示了将摄影影像视作科学证据的传统是纪录片意识形态力量的根本来源。 [50]虽然此时他们的论述并没有集中于真实性问题，但却从不同角度动摇了对纪录片真实性的主张。实际上，在“后直接电影”时期，对纪录片真实性的质疑与辨析已经成了西方纪录片理论核心内容之一。

      从格里尔逊领导的英国纪录片运动到北美的直接电影运动，纪录片的创作者、评论家乃至普通观众都相信纪录片可以向观众呈现真实。作为“纪录片”一词的始作俑者，格里尔逊提出纪录片是“对事实的创造性处理”。这里客观存在的经验事实是纪录片表达的基础。到了直接电影时期，虽然格里尔逊式纪录片的绝大多数表现手段都被视为非法，其真实性主张也受到了严重的质疑，但格里尔逊这种对真实的主张却被直接电影继承下来，甚至被空前程度地加以强化。温斯顿清楚地看到了格里尔逊式纪录片和直接电影之间在表现手段分歧下的这种认识论上的一致性。他形象地总结说：“直接电影教条是‘新约’，用以完成格里尔逊式的‘旧约’的承诺。” [51]至于同直接电影同时期在法国出现真实电影，虽然其代表人物让·鲁什（Jean Rouch）等人对纪录片真实性的理解与美国的德鲁等人完全不同，但他们也是将自己的影片视为对现实某一方面的真实反映。就这一点来说，它与直接电影并无不同。 [52]      在温斯顿看来，真正放弃这种真实性修辞的是1980年代后期以《细蓝线》、《罗杰和我》为代表的一批作品。这些新纪录片采用了另外一种完全不同的表达范式，其核心就是对真实性问题的不同理解。相应地，温斯顿将格里尔逊团队创作的作品和直接电影划归一处，统称为“格里尔逊式”纪录片（Griersonian documentary），将1980年代后期以来的纪录片称为“后格里尔逊式”纪录片（post-Griersonian documentary），同时将这一发展阶段称为“后格里尔逊”时期（post-Griersonian period）。

      温斯顿的这种术语选择当然有其道理。但笔者仍然愿意将这一阶段称为“后直接电影”时期（post-Direct Cinema period）。一方面这是由于二者在历史演进中有先后之别，以相邻的直接电影作为分界更合常理。另一方面，虽然二者都确信纪录片可以呈现真实，但它们对如何才能呈现真实却抱有截然不同的看法。这体现在二者对技术、手法、形式、风格等方面完全不同的选择上。温斯顿强调的二者之间的共通之处固然重要，但我们同样也不应忽略二者之间的巨大差异、甚至某些方面的完全对立。此外，1980年代后期以来的新纪录片往往以1960年代以来就占据统治地位的直接电影作为自身反叛的对象，而与更遥远的、已经被冷落的格里尔逊式纪录片无涉。有鉴于此，笔者放弃“后格里尔逊”而使用“后直接电影”的概念来描述这一时期。

      和温斯顿一样，绝大多数纪录片理论家自1970年代后期以来逐渐站到了后结构主义的立场上。在这些后结构主义理论家看来，在纪录片表达中，除意识形态之外再无他物，任何对客观、真实的主张都是令人怀疑的。到了1980年代，后现代主义思潮又进一步加剧了人们对纪录片客观性、真实性主张的怀疑。纪录片史学家埃里克·巴尔诺（Erik Barnouw）在他的名著《纪录片——非虚构电影史》（Documentary: A History of the Non-Fiction Film,1993）中写道：  不管他们（纪录片导演，译者注）采纳的是观察者的立场，或者是编年史家、画家乃至任何其他什么人的立场，他们始终无法回避自己的主观性。影片所呈现的世界是导演自己版本的世界。[53]  巴尔诺所说的这种普遍存在的主观性体现在作品形式上，就是尼科尔斯在1983年提出来的纪录片的“声音”（voice）。像axiographics、epistephilia等概念一样，voice也是尼科尔斯独创的纪录片理论关键词之一。 [54] 他解释说：“纪录片的声音就是一部电影对自身观察世界的方式的特定表达方式。” [55] 在这里，声音的存在是纪录片之所以成为纪录片的必要前提。这一点充分地体现到了尼科尔斯在2010年对纪录片所下的定义之中：  纪录片所讲述的情境或事件包含了故事中以本来面目呈现给我们的真人（社会演员），同时这些故事传递了创作者对影片中所描述的生活、情境和事件的某种看似有理的建议或看法。影片创作者独特的视点使得这个故事以一种直接的方式对这个历史世界进行观看，而不是使其成为一个虚构的寓言。[56]  这个定义除了强调纪录片中人物是真实的，再没有为纪录片设定任何其他的真实性、客观性方面的原则。在尼科尔斯看来，“它们（纪录片）与剧情片共享那些彻底破坏任何严格客观性的品质，如果它们不是使这种客观性变得全无可能。” [57]就这一判断，雷诺夫援引历史哲学的有关理论资源，做出了更进一步的阐述。

      在有关纪录片真实性的讨论中，琳达·威廉姆斯（Linda Williams） 1993年的文章《没有记忆的镜子》（Mirrors without Memories: Truth, History, and the New Documentary, 1993）在西方学界并没有受到更多关注，但它却对我们中国学界产生巨大影响，甚至催生了一个笔者所谓的“新纪录神话” [58]。威廉姆斯的这篇文章最引入注目之处是其对纪录片的“虚构”的某种张扬。实际上，比威廉姆斯更早对虚构这个概念详加阐述的是雷诺夫。 [59]在其主编的《理论化纪录片》一书中，雷诺夫专门撰写了一篇题为《非剧情片的真实》的导论。在这篇文章中，他借鉴后现代历史哲学创始人海登·怀特（Hayden White）对“转义”的分析，提出“……所有的推论形式，包括纪录片在内，如果不是虚构的（fictional），那至少也与虚构相关联（fictive）。原因在于他们转义（tropic）的性质（即他们依赖于比喻或者修辞形象进行表达，原文注）。” [60]在雷诺夫看来，就如同虚构内在于历史写作，虚构也内在于纪录片的表达，是纪录片无法逃脱的宿命。纪录片与剧情片之间远非壁垒森严，不通骑驿。恰恰相反，二者不仅在形式技巧上难分彼此，在表达机制上也本无不同。雷诺夫总结说：  任何的纪录片表达都依赖于其自身对于实在（the real）的绕行，这种绕行经由声画能指的路径来实现（通过对语言、镜头、接近性以及声音环境的选择，原文注）。这样，在纪录片中某项真实所经历的这个行程（这里的‘真实’应视作是提议式的和暂时的，原文注），在性质上与剧情片中的状况类似。 [61]      对于很多人来说，这样一种后结构主义的主张不免令人失望。如果纪录片真的不能获得任何形式的客观性或真实性，甚至和剧情片一样充满了“虚构”，那它还如何获确认自己的身份和价值呢？      就目前来说，理论界对于这一问题的回应还不充分。伊恩·艾特肯（Ian Aitken）在他主编的《纪录片百科全书》（Encyclopedia of the Documentary Film）中，曾试图运用科学哲学领域的最新发展来解释纪录片如何帮助人们认识和把握客观世界。 [62]这种解决问题的思路是对的，尽管就这篇文章本身来说，艾特肯并没有带领我们走出太远。另外有学者则对已经占据主导地位的后结构主义纪录片理论中可能存在的问题进行了直接反击。比如卡尔·普兰廷加就指责说，这种后结构主义、后现代主义的理论阐述作为一种哲学是不成立的，作为政治分析、政治行动的基础是失败的。 [63]与后结构主义理论相对，普兰廷加提出一种“工具主义”（instrumentalist）理论，以此来解释纪录片的表达。与普兰廷加持有相近立场的还有诺埃尔·卡罗尔。卡罗尔既是电影理论家，也是一名哲学家。他认为雷诺夫、尼科尔斯、温斯顿这些后结构主义理论家的论述在哲学基础上存在着严重缺陷。因此在一篇题为《非虚构电影与后现代怀疑主义》（Nonfiction Film and Postmodernist Skepticism）的文章中，卡罗尔对上述三位理论家进行了逐一的批驳，行文也充满火药味。 [64]对于这篇文章，雷诺夫、尼科尔斯未作更多回应。只有温斯顿在第二版《以真实的名义》中，专辟一节进行了反批评。 [65]就在这本书的序言中，温斯顿还谈到纷争不断的当代纪录片理论界仿佛是一个“战场” [66]。这当然是对纪录片理论发展现状的一个普遍概括，但不难猜想，这一定也是他非常切身的体验之一。

      5、纪录片的定义问题

      和真实性问题紧密相关的是纪录片的定义问题。前面曾经提到，约翰·格里尔逊曾提出纪录片史上第一个也是最具影响力的一个定义：对事实的创造性处理。但就像温斯顿一样，很多人都认为这个定义太过含混，甚至自相矛盾。 [67]萨雅吉·雷（Satyajit Ray）就曾指出：“……从某种意义上说，神话传说也是对现实的创造性处理。实际上，在所有非抽象艺术领域的所有艺术家都在追求那个被格里尔逊独独指派给纪录片创作者的目标。” [68]格里尔逊本人和他的追随者们对这一定义中的含混之处当然也心知肚明，否则格里尔逊不会说“纪录片”一词“言不及义”（clumsy）[69]，他的同事、著名导演阿尔贝托·卡瓦康蒂（Alberto Cavalcanti）也不会直言“它（纪录片）闻起来像垃圾，让人生厌”。 [70]只不过由于现实的考虑，他们有意无意将这一概念中隐含的矛盾掩盖起来了。 [71]      格里尔逊等人的掩盖当然是为了维护其对纪录片真实性的主张。实际上，直到1970年代中期，人们依然从真实性出发对纪录片进行定义。比如威廉·斯隆（William Sloan）就曾说：“在最宽泛的意义上，纪录片这个术语指那种具有真实性并呈现现实的影片，它们主要用于非剧场放映。” [72]在中文学界更具知名度的理论家理查德·巴萨姆（Richard Barsam）则在1976年的文章中全盘接受这个定义，只不过又奇怪地加了一个时间限定：一部纪录片“通常的长度是30分钟”。 [73]      在这一时期，有关纪录片定义最富洞见的阐述或许来自一位英国电视台的纪录片编辑戴·沃汉（Dai Vaughan）。也是在1976年，沃汉出版了一本30多页的小册子 《电视纪录片惯例》（Television Documentary Usage）。在这本书中，就纪录片的定义，沃汉提出了若干重要的论断。首先，纪录片不是“实体”（entity）,而是人们追求的一种理想。此时被认作是纪录片的作品，彼时可能就不是，因为不同的时代人们对“纪录片”概念的认识和期待可能完全不同。由于纪录片不是实体，其形式、风格等要素也就构不成其与剧情片相区别的基础。此外，沃汉还提出所有纪录片唯一的共性在于它们对“先在真实”（anterior truth）的主张, 即致力于在作品中呈现出现实世界的真相。在他看来，这才是纪录片与剧情片之间真正的区别。

      沃汉是一个纪录片创作者，不是理论家，这或许可以解释为什么他的这些超越时代的论述没有得到应得的重视。形式无法成为区别纪录片与剧情片的依据，因为在创作中纪录片与剧情片在形式上的彼此借鉴、模仿已经是司空见惯。虽然尼科尔斯对纪录片结构形式做出了若干重要的归纳，但这种归纳是描述性的，而不是规定性的。剧情片完全可以采用与纪录片同样的表达形式，“伪纪录片”的存在就是例证。另一方面，内容的真实与否与作品是否具有纪录片的身份也是两回事。且不说后结构主义、后现代主义对纪录片真实性的普遍怀疑，很多纪录片作品在经验层面就可以被明确指认为造假，比如纳粹德国制作的《意志的胜利》（Triumph of the Will）、我国文革其间制作的《用毛泽东思想治好全部聋哑儿童》等都是如此。这样我们就只能到文本之外去寻找纪录片与剧情片之间的区别。

      与沃汉的思路相去不远，在1983年的一篇文章中，诺埃尔·卡罗尔在文本之外提出了“标示”（index）的概念，以此来建立纪录片与剧情片的分别。他强调影片创作者、发行者对作品的标示足以帮助观众确认作品的身份，并促使其对作品做出相应的期待。 [74]到了1996年，卡罗尔又提出：“非剧情片和剧情片之间的区别在于文本承诺（commitment）上，而不在于文本表层结构上。” [75]这个“承诺”当然是指对真实性的承诺。很明显，这种说法与沃汉对纪录片“先在真实”的观察相距并不遥远。持有类似观点的还有卡尔·普兰廷加。他在1987年提出，纪录片与剧情片之间的区别在于二者采纳的不同的立场：剧情片采纳的是“虚构的立场”（fictive stance），非剧情片采纳的是“肯定性的立场”（assertive stance），非剧情片的独特之处在于它声称自己所呈现的内容是在现实世界真实发生过的。这样，界定纪录片的依据就从真实性本身转移到了对真实性的主张，从文本之内转向了文本之外的社会语境。

      几乎是对沃汉有关“实体”论述的直接呼应，约翰·康纳在2000年提出我们最好把“纪录片”当做形容词，而不是当做名词，因为这样“来得更安全些”。 [76]他写道：“问‘这是一个纪录片项目吗’比问‘这是一部纪录片吗’更有价值，因为后者暗示某些严格的定义标准，它似乎更多指向某种物体，而不是某种类型的操作实践。” [77]显然，康纳的这一说法和沃汉对实体的否定如出一辙，尽管二者相差了20多年。在同一个方向上，另一位理论家斯泰拉·布鲁兹比康纳的表达又更进了一步。她声称如果纪录片还是什么东西的话，那它就是“真实事件与对它的表现之间不断的协商（negotiation）”。[78]同样是超越了文本本身，同样是进入到文本生产、传播的社会语境，但“协商”一词则暗示我们，除了创作者的意图、策略、手法，要想充分理解纪录片这个概念，观众的接受行为不能被忽略。

      实际上，从1990年代以来，就有学者试图抛开文本本身，完全从观众接受角度来界定纪录片。这或许是近年来纪录片理论界最重要的努力之一。虽然尼科尔斯在1991年就对这一思路有所暗示[79]，但率先对此做出全面阐述的是温斯顿。温斯顿在第一版《以真实的名义》中明确提出，区别纪录片与剧情片的最佳方式是看观众对它们不同的接受方式。 [80]“纪录片之不同，基础并不在于表现（这里什么都无法被保证），更多在于接受（这里什么都不需要被保证）。” [81]      温斯顿的观点很快得到了更多的呼应。1999年，沃汉在雷诺夫等学者的盛邀之下，出版了自己的论文集《写给纪录片》（For Documentary）。在其中一篇文章中，沃汉明确谈到，“纪录片”作为一个术语指的“不是一种风格、方法或影片创作类型，而是对影片素材的一种反应”。 [82]这种反应的关键是将影片所呈现的内容与现实世界直接对应起来。同是1999年，作为“可见的证据”系列中的一本，《搜集可见的证据》（Collecting Visible Evidence）出版。其中著名学者维维安·索布切克（Vivian Sobchack）运用现象学的方法，将观众对家庭录像、纪录片、剧情片所做的不同反应置于一个连贯的谱系之上，进行比较分析。由此索布切克得出结论说：“‘纪录片’不是一个东西，而是与影片对象之间的一种主观性的关系。是观众的意识最终决定了影片对象的类型。” [83]      从观众接受角度界定纪录片会给纪录片表达带来极大的解放。从这一立场出发，影片内容是否是对现实的直接记录已经不再重要，唯一重要的是观众在观看影片时能够将影片内容与现实世界联系起来，确信影片内容是对现实世界的直接描述。如此一来，传统被视作虚构的表现手段，如数字动画、情景再现等，就获得了和纪实影像同等的合法性。当然，也不是说这一解决思路就是完美的。如果只强调接受，而对文本构成不做任何限定，那么有一个风险就是无论什么样的影像表达都可能被视作纪录片。就像尼科尔斯在其第一版《纪录片导论》开篇所说的：“所有电影都是纪录片”。 [84]如果走到如此极端的立场，那纪录片这个概念距离丧失使用价值也就不远了。

      温斯顿显然对这一问题有更清醒的认识。在一本即将出版的纪录片论文集的序言中，温斯顿对纪录片进行了重新界定。除了继续强调在文本之外，观众需要确信影片内容与现实的相关性，或者说创作者、发行者或作品标示本身要让观众确信这种相关性，影片还需要具备另外两个条件：一是影片所呈现的内容，抛开真实、准确与否不谈，一定要有相应的见证人（witness）；二是影片要有叙事（narrative）。这种见证可以是直接电影所要求的摄影机的直接见证，也可以是知情人、研究者、亲历者或其他被拍摄对象的见证。温斯顿这里所谈的叙事是一个广义的叙事，和尼科尔斯的“声音”的概念有切近之处。[85]由于这篇文章尚未发表，理论界会做出什么样的回应我们无从得知。但在笔者看来，这或许是目前所有有关纪录片的定义中，最成功的一个，尽管它似乎依然缺乏定义所应具备的简洁。

      过去30年间纪录片理论发展所涉及的议题多多，本文所讨论的只是其中很有限的一部分。比如从1970年代末就为温斯顿等学者所关注的纪录片伦理问题[86]，过去十几年间，雷诺夫一直关注的纪录片主体性问题 [87]，托马斯·奥斯丁（Thomas Austin）对观众接受行为的考察[88]等，本文都未能深入探讨。在后直接电影时代，创作领域中很多新的纪录片亚类型纷纷进入人们的视野，比如动画纪录片（animated documentary）、自传体纪录片（autobiographical documentary）、自我治疗纪录片（self-therapy documentary）、纪录剧（docudrama）、假定纪录片（conditional documentary）等。与这些纪录片相关的研究很多，本文也没有更多涉及。此外，很多重要学者都再次回到纪录片史，对重要的电影运动、重要的导演、作品进行重新考察，并获得了许多重要的发现。在我们回顾后直接电影时期纪录片理论的发展时，这些内容也都不应被忽略。',

      "'ডাক্তার! ডাক্তার!'

      জ্বালাতন করিল! এই অর্ধেক রাত্রে--

      চোখ মেলিয়া দেখি আমাদের জমিদার দক্ষিণাচরণবাবু। ধড়ফড় করিয়া উঠিয়া পিঠভাঙা চৌকিটা টানিয়া আনিয়া তাঁহাকে বসিতে দিলাম এবং উদ্‌বিগ্নভাবে তাঁহার মুখের দিকে চাহিলাম। ঘড়িতে দেখি, তখন রাত্রি আড়াইটা

      দক্ষিণাচরণবাবু বিবর্ণমুখে বিস্ফারিত নেত্রে কহিলেন, 'আজ রাত্রে আবার সেইরূপ উপদ্রব আরম্ভ হইয়াছে-- তোমার ঔষধ কোনো কাজে লাগিল না।'
      আমি কিঞ্চিৎ সসংকোচে বলিলাম, 'আপনি বোধ করি মদের মাত্রা আবার বাড়াইয়াছেন।'
      দক্ষিণাচরণবাবু অত্যন্ত বিরক্ত হইয়া কহিলেন, 'ওটা তোমার ভারি ভ্রম। মদ নহে; আদ্যোপান্ত বিবরণ না শুনিলে তুমি আসল কারণটা অনুমান করিতে পারিবে না।'
      কুলুঙ্গির মধ্যে ক্ষুদ্র টিনের ডিবায় ম্লানভাবে কেরোসিন জ্বলিতেছিল, আমি তাহা উস্‌কাইয়া দিলাম। একটুখানি আলো জাগিয়া উঠিল এবং অনেকখানি ধোঁয়া বাহির হইতে লাগিল। কোঁচাখানা গায়ের উপর টানিয়া একখানা খবরের-কাগজ-পাতা প্যাক্‌বাক্সের উপর বসিলাম। দক্ষিণাচরণবাবু বলিতে লাগিলেন--
      আমার প্রথমপক্ষের স্ত্রীর মতো এমন গৃহিণী অতি দুর্লভ ছিল। কিন্তু আমার তখন বয়স বেশি ছিল না, সহজেই রসাধিক্য ছিল, তাহার উপর আবার কাব্যশাস্ত্রটা ভালো করিয়া অধ্যয়ন করিয়াছিলাম, তাই অবিমিশ্র গৃহিণীপনায় মন উঠিত না। কালিদাসের সেই শ্লোকটা প্রায় মনে উদয় হইত--

      গৃহিণী সচিবঃ সখী মিথঃ প্রিয়শিষ্যা ললিতে কলাবিধৌ।  কিন্তু আমার গৃহিণীর কাছে ললিত কলাবিধির কোনো উপদেশ খাটিত না এবং সখী-ভাবে প্রণয়সম্ভাষণ করিতে গেলে তিনি হাসিয়া উড়াইয়া দিতেন। গঙ্গার স্রোতে যেমন ইন্দ্রের ঐরাবত নাকাল হইয়াছিল তেমনি তাঁহার হাসির মুখে বড়ো বড়ো কাব্যের টুকরা এবং ভালো ভালো আদরের সম্ভাষণ মুহূর্তের মধ্যে অপদস্থ হইয়া ভাসিয়া যাইত। তাঁহার হাসিবার আশ্চর্য ক্ষমতা ছিল

      তাহার পর, আজ বছর চারেক হইল আমাকে সাংঘাতিক রোগে ধরিল। ওষ্ঠব্রণ হইয়া জ্বরবিকার হইয়া, মরিবার দাখিল হইলাম। বাঁচিবার আশা ছিল না। একদিন এমন হইল যে, ডাক্তারে জবাব দিয়া গেল। এমন সময় আমার এক আত্মীয় কোথা হইতে এক ব্রহ্মচারী আনিয়া উপস্থিত করিল; সে গব্য ঘৃতের সহিত একটা শিকড় বাঁটিয়া আমাকে খাওয়াইয়া দিল। ঔষধের গুণেই হউক বা অদৃষ্টক্রমেই হউক সে-যাত্রা বাঁচিয়া গেলাম

      রোগের সময় আমার স্ত্রী অহর্নিশি এক মুহূর্তের জন্য বিশ্রাম করেন নাই। সেই কটা দিন একটি অবলা স্ত্রীলোক, মানুষের সামান্য শক্তি লইয়া প্রাণপণ ব্যাকুলতার সহিত, দ্বারে সমাগত যমদূতগুলার সঙ্গে অনবরত যুদ্ধ করিয়াছিলেন। তাঁহার সমস্ত প্রেম, সমস্ত হৃদয়, সমস্ত যত্ন দিয়া আমার এই অযোগ্য প্রাণটাকে যেন বক্ষের শিশুর মতো দুই হস্তে ঝাঁপিয়া ঢাকিয়া রাখিয়াছিলেন। আহার ছিল না, নিদ্রা ছিল না, জগতের আর-কোনো-কিছুর প্রতিই দৃষ্টিই ছিল না

      যম তখন পরাহত ব্যাঘ্রের ন্যায় আমাকে তাঁহার কবল হইতে ফেলিয়া দিয়া চলিয়া গেলেন, কিন্তু, যাইবার সময় আমার স্ত্রীকে একটা প্রবল থাবা মারিয়া গেলেন

      আমার স্ত্রী তখন গর্ভবতী ছিলেন, অনতিকাল পরে এক মৃত সন্তান প্রসব করিলেন। তাহার পর হইতেই তাঁহার নানাপ্রকার জটিল ব্যামোর সূত্রপাত হইল। তখন আমি তাঁহার সেবা আরম্ভ করিয়া দিলাম। তাহাতে তিনি বিব্রত হইয়া উঠিলেন। বলিতে লাগিলেন, 'আঃ, করো কী! লোকে বলিবে কী! অমন করিয়া দিনরাত্রি তুমি আমার ঘরে যাতায়াত করিয়ো না।'     যেন নিজে পাখা খাইতেছি, এইরূপ ভান করিয়া রাত্রে যদি তাঁহাকে তাঁহার জ্বরের সময় পাখা করিতে যাইতাম তো ভারি একটা কাড়াকাড়ি ব্যাপার পড়িয়া যাইত। কোনোদিন যদি তাঁহার শুশ্রূষা উপলক্ষে আমার আহারের নিয়মিত সময় দশ মিনিট উত্তীর্ণ হইয়া যাইত, তবে সেও নানাপ্রকার অনুনয় অনুরোধ অনুযোগের কারণ হইয়া দাঁড়াইত। স্বল্পমাত্র সেবা করিতে গেলে হিতে বিপরীত হইয়া উঠিত। তিনি বলিতেন, 'পুরুষমানুষের অতটা বাড়াবাড়ি ভালো নয়।'     আমাদের সেই বরানগরের বাড়িটি বোধ করি তুমি দেখিয়াছ। বাড়ির সামনেই বাগান এবং বাগানের সম্মুখেই গঙ্গা বহিতেছে। আমাদের শোবার ঘরের নীচেই দক্ষিণের দিকে খানিকটা জমি মেহেদির বেড়া দিয়া ঘিরিয়া আমার স্ত্রী নিজের মনের মতো একটুকরা বাগান বানাইয়াছিলেন। সমস্ত বাগানটির মধ্যে সেই খণ্ডটিই অত্যন্ত সাদাসিধা এবং নিতান্ত দিশি। অর্থাৎ, তাহার মধ্যে গন্ধের অপেক্ষা বর্ণের বাহার, ফুলের অপেক্ষা পাতার বৈচিত্র্য ছিল না, এবং টবের মধ্যে অকিঞ্চিৎকর উদ্ভিজ্জের পার্শ্বে কাঠি অবলম্বন করিয়া কাগজে নির্মিত লাটিন নামের জয়ধ্বজা উড়িত না। বেল, জুঁই, গোলাপ, গন্ধরাজ, করবী এবং রজনীগন্ধারই প্রাদুর্ভাব কিছু বেশি। প্রকাণ্ড একটা বকুলগাছের তলা সাদা মার্বল পাথর দিয়া বাঁধানো ছিল। সুস্থ অবস্থায় তিনি নিজে দাঁড়াইয়া দুইবেলা তাহা ধুইয়া সাফ করাইয়া রাখিতেন। গ্রীষ্মকালে কাজের অবকাশে সন্ধ্যার সময় সেই তাঁহার বসিবার স্থান ছিল। সেখান হইতে গঙ্গা দেখা যাইত কিন্তু গঙ্গা হইতে কুঠির পানসির বাবুরা তাঁহাকে দেখিতে পাইত না

      অনেকদিন শয্যাগত থাকিয়া একদিন চৈত্রের শুক্লপক্ষ সন্ধ্যায় তিনি কহিলেন, 'ঘরে বদ্ধ থাকিয়া আমার প্রাণ কেমন করিতেছে; আজ একবার আমার সেই বাগানে গিয়া বসিব।'
      আমি তাঁহাকে বহু যত্নে ধরিয়া ধীরে ধীরে সেই বকুলতলের প্রস্তরবেদিকায় লইয়া গিয়া শয়ন করাইয়া দিলাম। আমারই জানুর উপরে তাঁহার মাথাটি তুলিয়া রাখিতে পারিতাম, কিন্তু জানি সেটাকে তিনি অদ্ভুত আচরণ বলিয়া গণ্য করিবেন, তাই একটি বালিশ আনিয়া তাঁহার মাথার তলায় রাখিলাম

      দুটি-একটি করিয়া প্রস্ফুট বকুল ফুল ঝরিতে লাগিল এবং শাখান্তরাল হইতে ছায়াঙ্কিত জ্যোৎস্না তাঁহার শীর্ণ মুখের উপর আসিয়া পড়িল। চারি দিক শান্ত নিস্তব্ধ, সেই ঘনগন্ধপূর্ণ ছায়ান্ধকারে একপার্শ্বে নীরবে বসিয়া তাঁহার মুখের দিকে চাহিয়া আমার চোখে জল আসিল

      আমি ধীরে ধীরে কাছের গোড়ায় আসিয়া দুই হস্তে তাঁহার একটি উত্তপ্ত শীর্ণ হাত তুলিয়া লইলাম। তিনি তাহাতে কোনো আপত্তি করিলেন না। কিছুক্ষণ এইরূপ চুপ করিয়া বসিয়া থাকিয়া আমার হৃদয় কেমন উদ্‌বেলিত হইয়া উঠিল, আমি বলিয়া উঠিলাম, 'তোমার ভালোবাসা আমি কোনোকালে ভুলিব না।'     তখনি বুঝিলাম, কথাটা বলিবার কোনো আবশ্যক ছিল না। আমার স্ত্রী হাসিয়া উঠিলেন। সে হাসিতে লজ্জা ছিল, সুখ ছিল এবং কিঞ্চিৎ অবিশ্বাস ছিল এবং উহার মধ্যে অনেকটা পরিমাণে পরিহাসের তীব্রতাও ছিল। প্রতিবাদস্বরূপে একটি কথামাত্র না বলিয়া কেবল তাঁহার সেই হাসির দ্বারা জানাইলেন, 'কোনোকালে ভুলিবে না, ইহা কখনো সম্ভব নহে এবং আমি তাহা প্রত্যাশাও করি না।'     ঐ সুমিষ্ট সুতীক্ষ্ণ হাসির ভয়েই আমি কখনো আমার স্ত্রীর সঙ্গে রীতিমত প্রেমালাপ করিতে সাহস করি নাই। অসাক্ষাতে যে-সকল কথা মনে উদয় হইত, তাঁহার সম্মুখে গেলেই সেগুলাকে নিতান্ত বাজে কথা বলিয়া বোধ হইত। ছাপার অক্ষরে যে-সব কথা পড়িলে দুই চক্ষু বাহিয়া দর দর ধারায় জল পড়িতে থাকে সেইগুলা মুখে বলিতে গেলে কেন যে হাস্যের উদ্রেক করে, এ পর্যন্ত বুঝিতে পারিলাম না

      বাদপ্রতিবাদ কথায় চলে কিন্তু হাসির উপরে তর্ক চলে না, কাজেই চুপ করিয়া যাইতে হইল। জ্যোৎস্না উজ্জ্বলতর হইয়া উঠিল, একটা কোকিল ক্রমাগতই কুহু কুহু ডাকিয়া অস্থির হইয়া গেল। আমি বসিয়া বসিয়া ভাবিতে লাগিলাম, এমন জ্যোৎস্নারাত্রেও কি পিকবধূ বধির হইয়া আছে

      বহু চিকিৎসায় আমার স্ত্রীর রোগ-উপশমের কোনো লক্ষণ দেখা গেল না। ডাক্তার বলিল, 'একবার বায়ু পরিবর্তন করিয়া দেখিলে ভালো হয়।' আমি স্ত্রীকে লইয়া এলাহাবাদে গেলাম

      এইখানে দক্ষিণাবাবু হঠাৎ থমকিয়া চুপ করিলেন। সন্দিগ্ধভাবে আমার মুখের দিকে চাহিলেন, তাহার পর দুই হাতের মধ্যে মাথা রাখিয়া ভাবিতে লাগিলেন। আমিও চুপ করিয়া রহিলাম। কুলুঙ্গিতে কেরোসিন মিটমিট করিয়া জ্বলিতে লাগিল এবং নিস্তব্ধ ঘরে মশার ভন্‌ভন্‌ শব্দ সুস্পষ্ট হইয়া উঠিল। হঠাৎ মৌন ভঙ্গ করিয়া দক্ষিণাবাবু বলিতে আরম্ভ করিলেন--     সেখানে হারান ডাক্তার আমার স্ত্রীকে চিকিৎসা করিতে লাগিলেন

      অবশেষে অনেককাল একভাবে কাটাইয়া ডাক্তারও বলিলেন, আমিও বুঝিলাম এবং আমার স্ত্রীও বুঝিলেন যে, তাঁহার ব্যামো সারিবার নহে। তাঁহাকে চিররুগ্‌ণ হইয়াই কাটাইতে হইবে

      তখন একদিন আমার স্ত্রী আমাকে বলিলেন,'যখন ব্যামোও সারিবে না এবং শীঘ্র আমার মরিবার আশাও নাই তখন আর-কতদিন এই জীবন্‌মৃতকে লইয়া কাটাইবে। তুমি আর-একটা বিবাহ করো।'
      এটা যেন কেবল একটা সুযুক্তি এবং সদ্‌বিবেচনার কথা-- ইহার মধ্যে যে, ভারি একটা মহত্ত্ব বীরত্ব বা অসামান্য কিছু আছে, এমন ভাব তাঁহার লেশমাত্র ছিল না

      এইবার আমার হাসিবার পালা ছিল। কিন্তু, আমার কি তেমন করিয়া হাসিবার ক্ষমতা আছে। আমি উপন্যাসের প্রধান নায়কের ন্যায় গম্ভীর সমুচ্চভাবে বলিতে লাগিলাম,'যতদিন এই দেহে জীবন আছে--'
      তিনি বাধা দিয়া কহিলেন, 'নাও নাও! আর বলিতে হইবে না। তোমার কথা শুনিয়া আমি আর বাঁচি না!'     আমি পরাজয় স্বীকার না করিয়া বলিলাম,'এ জীবনে আর-কাহাকেও ভালোবাসিতে পারিব না।'     শুনিয়া আমার স্ত্রী ভারি হাসিয়া উঠিলেন। তখন আমাকে ক্ষান্ত হইতে হইল

      জানি না, তখন নিজের কাছেও কখনো স্পষ্ট স্বীকার করিয়াছি কি না কিন্তু এখন বুঝিতে পারিতেছি, এই আরোগ্য-আশাহীন সেবাকার্যে আমি মনে মনে পরিশ্রান্ত হইয়া গিয়াছিলাম। এ কার্যে যে ভঙ্গ দিব, এমন কল্পনাও আমার মনে ছিল না; অথচ চিরজীবন এই চিররুগ্‌ণকে লইয়া যাপন করিতে হইবে, এ কল্পনাও আমার নিকট পীড়াজনক হইয়াছিল। হায়, প্রথম যৌবনকালে যখন সম্মুখে তাকাইয়াছিলাম তখন প্রেমের কুহকে, সুখের আশ্বাসে, সৌন্দর্যের মরীচিকায় সমস্ত ভবিষ্যৎ জীবন প্রফুল্ল দেখাইতেছিল। আজ হইতে শেষ পর্যন্ত কেবলই আশাহীন সুদীর্ঘ সতৃষ্ণ মরুভূমি

      আমার সেবার মধ্যে সেই আন্তরিক শ্রান্তি নিশ্চই তিনি দেখিতে পাইয়াছিলেন। তখন জানিতাম না কিন্তু এখন সন্দেহমাত্র নাই যে, তিনি আমাকে যুক্তাক্ষরহীন প্রথমভাগ শিশুশিক্ষার মতো অতি সহজে বুঝিতেন। সেইজন্য যখন উপন্যাসের নায়ক সাজিয়া গম্ভীরভাবে তাঁহার নিকট কবিত্ব ফলাইতে যাইতাম তিনি এমন সুগভীর স্নেহ অথচ অনিবার্য কৌতুকের সহিত হাসিয়া উঠিতেন। আমার নিজের অগোচর অন্তরের কথাও অন্তর্যামীর ন্যায় তিনি সমস্তই জানিতেন, এ কথা মনে করিলে আজও লজ্জায় মরিয়া যাইতে ইচ্ছা করে

      হারান ডাক্তার আমাদের স্বজাতীয়। তাঁহার বাড়িতে আমার প্রায়ই নিমন্ত্রণ থাকিত। কিছুদিন যাতায়াতের পর ডাক্তার তাঁহার মেয়েটির সঙ্গে আমার পরিচয় করাইয়া দিলেন। মেয়েটি অবিবাহিত; তাহার বয়স পনেরো হইবে। ডাক্তার বলেন, তিনি মনের মতো পাত্র পান নাই বলিয়া বিবাহ দেন নাই। কিন্তু বাহিরের লোকের কাছে গুজব শুনিতাম-- মেয়েটির কুলের দোষ ছিল

      কিন্তু, আর কোনো দোষ ছিল না। যেমন সুরূপ তেমনি সুশিক্ষা। সেইজন্য মাঝে মাঝে এক-একদিন তাঁহার সহিত নানা কথার আলোচনা করিতে করিতে আমার বাড়ি ফিরিতে রাত হইত, আমার স্ত্রীকে ঔষধ খাওয়াইবার সময় উত্তীর্ণ হইয়া যাইত। তিনি জানিতেন, আমি হারান ডাক্তারের বাড়ি গিয়াছি কিন্তু বিলম্বের কারণ একদিনও আমাকে জিজ্ঞাসাও করেন নাই

      মরুভূমির মধ্যে আর-একবার মরীচিকা দেখিতে লাগিলাম। তৃষ্ণা যখন বুক পর্যন্ত তখন চোখের সামনে কূলপরিপূর্ণ স্বচ্ছ জল ছলছল ঢলঢল করিতে লাগিল। তখন মনকে প্রাণপণে টানিয়া আর ফিরাইতে পারিলাম না

      রোগীর ঘর আমার কাছে দ্বিগুণ নিরানন্দ হইয়া উঠিল। তখন প্রায়ই শুশ্রূষা করিবার এবং ঔষধ খাওয়াইবার নিয়ম ভঙ্গ হইতে লাগিল

      হারান ডাক্তার আমাকে প্রায় মাঝে মাঝে বলিতেন, যাহাদের রোগ আরোগ্য হইবার কোনো সম্ভাবনা নাই, তাহাদের পক্ষে মৃত্যুই ভালো; কারণ, বাঁচিয়া তাহাদের নিজেরও সুখ নাই, অন্যেরও অসুখ। কথাটা সাধারণভাবে বলিতে দোষ নাই, তথাপি আমার স্ত্রীকে লক্ষ্য করিয়া এমন প্রসঙ্গ উত্থাপন করা তাঁহার উচিত হয় নাই। কিন্তু, মানুষের জীবনমৃত্যু সম্বন্ধে ডাক্তারের মন এমন অসাড় যে, তাহারা ঠিক আমাদের মনের অবস্থা বুঝিতে পারে না

      হঠাৎ একদিন পাশের ঘর হইতে শুনিতে পাইলাম, আমার স্ত্রী হারানবাবুকে বলিতেছেন, 'ডাক্তার, কতকগুলা মিথ্যা ঔষধ গিলাইয়া ডাক্তারখানার দেনা বাড়াইতেছ কেন। আমার প্রাণটাই যখন একটা ব্যামো, তখন এমন একটা ওষুধ দাও যাহাতে শীঘ্র এই প্রাণটা যায়।'     ডাক্তার বলিলেন, 'ছি, এমন কথা বলিবেন না।'     কথাটা শুনিয়া হঠাৎ আমার বক্ষে বড়ো আঘাত লাগিল। ডাক্তার চলিয়া গেলে আমার স্ত্রীর ঘরে গিয়া তাঁহার শয্যাপ্রান্তে বসিলাম, তাঁহার কপালে ধীরে ধীরে হাত বুলাইয়া দিতে লাগিলাম। তিনি কহিলেন,'এ ঘর বড়ো গরম, তুমি বাহিরে যাও। তোমার বেড়াইতে যাইবার সময় হইয়াছে। খানিকটা না বেড়াইয়া আসিলে আবার রাত্রে তোমার ক্ষুধা হইবে না।'     বেড়াইতে যাওয়ার অর্থ ডাক্তারের বাড়ি যাওয়া। আমিই তাঁহাকে বুঝাইয়াছিলাম, ক্ষুধাসঞ্চারের পক্ষে খানিকটা বেড়াইয়া আসা বিশেষ আবশ্যক। এখন নিশ্চয় বলিতে পারি, তিনি প্রতিদিনই আমার এই ছলনাটুকু বুঝিতেন। আমি নির্বোধ, মনে করিতাম তিনি নির্বোধ

      এই বলিয়া দক্ষিণাচরণবাবু অনেকক্ষণ করতলে মাথা রাখিয়া চুপ করিয়া বসিয়া রহিলেন। অবশেষে কহিলেন, 'আমাকে একগ্লাস জল আনিয়া দাও।' জল খাইয়া বলিতে লাগিলেন--     একদিন ডাক্তারবাবুর কন্যা মনোরমা আমার স্ত্রীকে দেখিতে আসিবার ইচ্ছা প্রকাশ করিলেন। জানি না, কী কারণে তাঁহার সে প্রস্তাব আমার ভালো লাগিল না। কিন্তু, প্রতিবাদ করিবার কোনো হেতু ছিল না। তিনি একদিন সন্ধ্যাবেলায় আমাদের বাসায় আসিয়া উপস্থিত হইলেন

      সেদিন আমার স্ত্রীর বেদনা অন্য দিনের অপেক্ষা কিছু বাড়িয়া উঠিয়াছিল। যেদিন তাঁহার ব্যথা বাড়ে সেদিন তিনি অত্যন্ত স্থির নিস্তব্ধ হইয়া থাকেন; কেবল মাঝে মাঝে মুষ্টি বদ্ধ হইতে থাকে এবং মুখ নীল হইয়া আসে, তাহাতেই তাঁহার যন্ত্রণা বুঝা যায়। ঘরে কোনো সাড়া ছিল না, আমি শয্যাপ্রান্তে চুপ করিয়া বসিয়া ছিলাম; সেদিন আমাকে বেড়াইতে যাইতে অনুরোধ করেন এমন সামর্থ্য তাঁহার ছিল না কিংবা হয়তো বড়ো কষ্টের সময় আমি কাছে থাকি, এমন ইচ্ছা তাঁহার মনে মনে ছিল। চোখে লাগিবে বলিয়া কেরোসিনের আলোটা দ্বারের পার্শ্বে ছিল। ঘর অন্ধকার এবং নিস্তব্ধ। কেবল এক-একবার যন্ত্রণার কিঞ্চিৎ উপশমে আমার স্ত্রীর গভীর দীর্ঘনিশ্বাস শুনা যাইতেছিল

      এমন সময়ে মনোরমা ঘরের প্রবেশদ্বারে দাঁড়াইলেন। বিপরীত দিক হইতে কেরোসিনের আলো আসিয়া তাঁহার মুখের উপর পড়িল। আলো-আঁধারে লাগিয়া তিনি কিছুক্ষণ ঘরের কিছুই দেখিতে না পাইয়া দ্বারের নিকট দাঁড়াইয়া ইতস্তত করিতে লাগিলেন

      আমার স্ত্রী চমকিয়া আমার হাত ধরিয়া জিজ্ঞাসা করিলেন, 'ও কে!'-- তাঁহার সেই দুর্বল অবস্থায় হঠাৎ অচেনা লোক দেখিয়া ভয় পাইয়া আমাকে দুই-তিনবার অস্ফুটস্বরে প্রশ্ন করিলেন, 'ও কে! ও কে গো!'     আমার কেমন দুর্‌বুদ্ধি হইল প্রথমেই বলিয়া ফেলিলাম, 'আমি চিনি না।' বলিবামাত্রই কে যেন আমাকে কশাঘাত করিল। পরের মুহূর্তেই বলিলাম, 'ওঃ, আমাদের ডাক্তারবাবুর কন্যা!'     স্ত্রী একবার আমার মুখের দিকে চাহিলেন; আমি তাঁহার মুখের দিকে চাহিতে পারিলাম না। পরক্ষণেই তিনি ক্ষীণস্বরে অভ্যাগতকে বলিলেন, 'আপনি আসুন।' আমাকে বলিলেন, 'আলোটা ধরো।'     মনোরমা ঘরে আসিয়া বসিলেন। তাঁহার সহিত রোগিণীর অল্পস্বল্প আলাপ চলিতে লাগিল। এমন সময় ডাক্তারবাবু আসিয়া উপস্থিত হইলেন

      তিনি তাঁহার ডাক্তারখানা হইতে দুই শিশি ওষুধ সঙ্গে আনিয়াছিলেন। সেই দুটি শিশি বাহির করিয়া আমার স্ত্রীকে বলিলেন, 'এই নীল শিশিটা মালিশ করিবার,আর এইটি খাইবার। দেখিবেন, দুইটাতে মিলাইবেন না, এ ওষুধটা ভারি বিষ।'     আমাকেও একবার সতর্ক করিয়া দিয়া ঔষধ দুটি শয্যাপার্শ্ববর্তী টেবিলে রাখিয়া দিলেন। বিদায় লইবার সময় ডাক্তার তাঁহার কন্যাকে ডাকিলেন

      মনোরমা কহিলেন, 'বাবা, আমি থাকি-না কেন। সঙ্গে স্ত্রীলোক কেহ নাই, ইঁহাকে সেবা করিবে কে?'     আমার স্ত্রী ব্যস্ত হইয়া উঠিলেন; বলিলেন, 'না,না, আপনি কষ্ট করিবেন না। পুরানো ঝি আছে, সে আমাকে মায়ের মতো যত্ন করে।'     ডাক্তার হাসিয়া বলিলেন, 'উনি মা-লক্ষ্ণী, চিরকাল পরের সেবা করিয়া আসিয়াছেন, অন্যের সেবা সহিতে পারেন না।'     কন্যাকে লইয়া ডাক্তার গমনের উদ্‌যোগ করিতেছেন এমন সময় আমার স্ত্রী বলিলেন, 'ডাক্তারবাবু, ইনি এই বদ্ধঘরে অনেকক্ষণ বসিয়া আছেন, ইঁহাকে একবার বাহিরে বেড়াইয়া লইয়া আসিতে পারেন?'     ডাক্তারবাবু আমাকে কহিলেন, 'আসুন-না, আপনাকে নদীর ধার হইয়া একবার বেড়াইয়া আনি।'     আমি ঈষৎ আপত্তি দেখাইয়া অনতিবিলম্বে সম্মত হইলাম। ডাক্তারবাবু যাইবার সময় দুই শিশি ঔষধ সম্বন্ধে আবার আমার স্ত্রীকে সতর্ক করিয়া দিলেন

      সেদিন ডাক্তারের বাড়িতেই আহার করিলাম। ফিরিয়া আসিতে রাত হইল। আসিয়া দেখি আমার স্ত্রী ছট্‌ফট্‌ করিতেছেন। অনুতাপে বিদ্ধ হইয়া জিজ্ঞাসা করিলাম, 'তোমার কি ব্যথা বাড়িয়াছে।'     তিনি উত্তর করিতে পারিলেন না, নীরবে আমার মুখের দিকে চাহিলেন। তখন তাঁহার কণ্ঠরোধ হইয়াছে

      আমি তৎক্ষণাৎ সেই রাত্রেই ডাক্তারকে ডাকিয়া আনিলাম

      ডাক্তার প্রথমটা আসিয়া অনেকক্ষণ কিছুই বুঝিতে পারিলেন না। অবশেষে জিজ্ঞাসা করিলেন,'সেই ব্যথাটা কি বাড়িয়া উঠিয়াছে। ঔষধটা একবার মালিশ করিলে হয় না?'     বলিয়া শিশিটা টেবিল হইতে লইয়া দেখিলেন, সেটা খালি

      আমার স্ত্রীকে জিজ্ঞাসা করিলেন, 'আপনি কি ভুল করিয়া এই ওষুধটা খাইয়াছেন?'     আমার স্ত্রী ঘাড় নাড়িয়া নীরবে জানাইলেন, 'হাঁ।'     ডাক্তার তৎক্ষণাৎ গাড়ি করিয়া তাঁহার বাড়ি হইতে পাম্প্‌ আনিতে ছুটিলেন। আমি অর্ধমূর্ছিতের ন্যায় আমার স্ত্রীর বিছানার উপর গিয়া পড়িলাম

      তখন, মাতা তাহার পীড়িত শিশুকে যেমন করিয়া সান্ত্বনা করে তেমনি করিয়া তিনি আমার মাথা তাঁহার বক্ষের কাছে টানিয়া লইয়া দুই হস্তের স্পর্শে আমাকে তাহার মনের কথা বুঝাইতে চেষ্টা করিলেন। কেবল তাঁহার সেই করুণ স্পর্শের দ্বারাই আমাকে বারংবার করিয়া বলিতে লাগিলেন, 'শোক করিয়ো না, ভালোই হইয়াছে, তুমি সুখী হইবে, এবং সেই মনে করিয়া আমি সুখে মরিলাম।'     ডাক্তার যখন ফিরিলেন, তখন জীবনের সঙ্গে সঙ্গে আমার স্ত্রীর সকল যন্ত্রণার অবসান হইয়াছে

      দক্ষিণাচরণ আর-একবার জল খাইয়া বলিলেন, 'উঃ, বড়ো গরম!' বলিয়া দ্রুত বাহির হইয়া বারকয়েক বারান্দায় পায়চারি করিয়া বসিলেন। বেশ বোঝা গেল, তিনি বলিতে চাহেন না কিন্তু আমি যেন জাদু করিয়া তাঁহার নিকট হইতে কথা কাড়িয়া লইতেছি। আবার আরম্ভ করিলেন--     মনোরমাকে বিবাহ করিয়া দেশে ফিরিলাম

      মনোরমা তাহার পিতার সম্মতিক্রমে আমাকে বিবাহ করিল; কিন্তু আমি যখন তাহাকে আদরের কথা বলিতাম, প্রেমালাপ করিয়া তাহার হৃদয় অধিকার করিবার চেষ্টা করিতাম, সে হাসিত না, গম্ভীর হইয়া থাকিত। তাহার মনের কোথায় কোন্‌খানে কী খটকা লাগিয়া গিয়াছিল, আমি কেমন করিয়া বুঝিব?     এইসময় আমার মদ খাইবার নেশা অত্যন্ত বাড়িয়া উঠিল

      একদিন প্রথম শরতের সন্ধ্যায় মনোরমাকে লইয়া আমাদের বরানগরের বাগানে বেড়াইতেছি। ছম্‌ছমে অন্ধকার হইয়া আসিয়াছে। পাখিদের বাসায় ডানা ঝাড়িবার শব্দটুকুও নাই। কেবল বেড়াইবার পথের দুইধারে ঘনছায়াবৃত ঝাউগাছ বাতাসে সশব্দে কাঁপিতেছিল

      শ্রান্তি বোধ করিতেই মনোরমা সেই বকুলতলার শুভ্র পাথরের বেদীর উপর আসিয়া নিজের দুই বাহুর উপর মাথা রাখিয়া শয়ন করিল। আমিও কাছে আসিয়া বসিলাম

      সেখানে অন্ধকার আরো ঘনীভূত; যতটুকু আকাশ দেখা যাইতেছে একেবারে তারায় আচ্ছন্ন; তরুতলের ঝিল্লিধ্বনি যেন অনন্তগগনবক্ষচ্যুত নিঃশব্দতার নিম্নপ্রান্তে একটি শব্দের সরু পাড় বুনিয়া দিতেছে

      সেদিনও বৈকালে আমি কিছু মদ খাইয়াছিলাম, মনটা বেশ একটু তরলাবস্থায় ছিল। অন্ধকার যখন চোখে সহিয়া আসিল তখন বনচ্ছায়াতলে পাণ্ডুর বর্ণে অঙ্কিত সেই শিথিল-অঞ্চল শ্রান্তকায় রমণীর আবছায়া মূর্তিটি আমার মনে এক অনিবার্য আবেগের সঞ্চার করিল। মনে হইল, ও যেন একটি ছায়া,ওকে যেন কিছুতেই দুই বাহু দিয়া ধরিতে পারিব না

      এমন সময় অন্ধকার ঝাউগাছের শিখরদেশে যেন আগুন ধরিয়া উঠিল; তাহার পরে কৃষ্ণপক্ষের জীর্ণপ্রান্ত হলুদবর্ণ চাঁদ ধীরে ধীরে গাছের মাথার উপরকার আকাশে আরোহণ করিল; সাদা পাথরের উপর সাদা শাড়িপরা সেই শ্রান্তশয়ান রমণীর মুখের উপর জ্যোৎস্না আসিয়া পড়িল। আমি আর থাকিতে পারিলাম না। কাছে আসিয়া দুই হাতে তাহার হাতটি তুলিয়া ধরিয়া কহিলাম, 'মনোরমা, তুমি আমাকে বিশ্বাস কর না, কিন্তু তোমাকে আমি ভালোবাসি। তোমাকে আমি কোনোকালে ভুলিতে পারিব না।'     কথাটা বলিবামাত্র চমকিয়া উঠিলাম; মনে পড়িল, ঠিক এই কথাটা আর একদিন আর কাহাকেও বলিয়াছি! এবং সেই মুহূর্তেই বকুলগাছের শাখার উপর দিয়া ঝাউ গাছের মাথার উপর দিয়া,কৃষ্ণপক্ষের পীতবর্ণ ভাঙা চাঁদের নীচে দিয়া গঙ্গার পূর্বপার হইতে গঙ্গার সুদূর পশ্চিম পার পর্যন্ত হাহা-- হাহা-- হাহা করিয়া অতি দ্রুতবেগে একটা হাসি বহিয়া গেল। সেটা মর্মভেদী হাসি কি অভ্রভেদী হাহাকার, বলিতে পারি না। আমি তদ্দণ্ডেই পাথরের বেদীর উপর হইতে মূর্ছিত হইয়া নীচে পড়িয়া গেলাম

      মূর্ছাভঙ্গে দেখিলাম, আমার ঘরে বিছানায় শুইয়া আছি। স্ত্রী জিজ্ঞাসা করিলেন, 'তোমার হঠাৎ এমন হইল কেন?'     আমি কাঁপিয়া উঠিয়া বলিলাম, 'শুনিতে পাও নাই, সমস্ত আকাশ ভরিয়া হাহা করিয়া একটা হাসি বহিয়া গেল?'     স্ত্রী হাসিয়া কহিলেন, 'সে বুঝি হাসি? সার বাঁধিয়া দীর্ঘ একঝাঁক পাখি উড়িয়া গেল, তাহাদেরই পাখার শব্দ শুনিয়াছিলাম। তুমি এত অল্পেই ভয় পাও?'     দিনের বেলায় স্পষ্ট বুঝিতে পারিলাম, পাখির ঝাঁক উড়িবার শব্দই বটে, এই সময়ে উত্তরদেশ হইতে হংসশ্রেণী নদীর চরে চরিবার জন্য আসিতেছে। কিন্তু সন্ধ্যা হইলে সে বিশ্বাস রাখিতে পারিতাম না। তখন মনে হইত, চারি দিকে সমস্ত অন্ধকার ভরিয়া ঘন হাসি জমা হইয়া রহিয়াছে, সামান্য একটা উপলক্ষে হঠাৎ আকাশ ভরিয়া অন্ধকার বিদীর্ণ করিয়া ধ্বনিত হইয়া উঠিবে। অবশেষে এমন হইল, সন্ধ্যার পর মনোরমার সহিত একটা কথা বলিতে আমার সাহস হইত না।     তখন আমাদের বরানগরের বাড়ি ছাড়িয়া মনোরমাকে লইয়া বোটে করিয়া বাহির হইলাম। অগ্রহায়ণ মাসে নদীর বাতাসে সমস্ত ভয় চলিয়া গেল। কয়দিন বড়ো সুখে ছিলাম। চারি দিকের সৌন্দর্যে আকৃষ্ট হইয়া মনোরমাও যেন তাহার হৃদয়ের রুদ্ধ দ্বার অনেকদিন পরে ধীরে ধীরে আমার নিকট খুলিতে লাগিল।     গঙ্গা ছাড়াইয়া খ'ড়ে ছাড়াইয়া অবশেষে পদ্মায় আসিয়া পৌঁছিলাম। ভয়ংকরী পদ্মা তখন হেমন্তের বিবরলীন ভুজঙ্গিনীর মতো কৃশ নির্জীবভাবে সুদীর্ঘ শীতনিদ্রায় নিবিষ্ট ছিল। উত্তর পারে জনশূন্য তৃণশূন্য দিগন্তপ্রসারিত বালির চর ধূ ধূ করিতেছে, এবং দক্ষিণের উচ্চ পাড়ের উপর গ্রামের আমবাগানগুলি এই রাক্ষসী নদীর নিতান্ত মুখের কাছে জোড়হস্তে দাঁড়াইয়া কাঁপিতেছে; পদ্মা ঘুমের ঘোরে এক-একবার পাশ ফিরিতেছে এবং বিদীর্ণ তটভূমি ঝুপ্‌ ঝাপ্‌ করিয়া ভাঙিয়া ভাঙিয়া পড়িতেছে।     এইখানে বেড়াইবার সুবিধা দেখিয়া বোট বাঁধিলাম।     একদিন আমারা দুইজনে বেড়াইতে বেড়াইতে বহুদূরে চলিয়া গেলাম। সূর্যাস্তের স্বর্ণচ্ছায়া মিলাইয়া যাইতেই শুক্লপক্ষের নির্মল চন্দ্রালোক দেখিতে দেখিতে ফুটিয়া উঠিল। সেই অন্তহীন শুভ্র বালির চরের উপর যখন অজস্র অবারিত উচ্ছ্বসিত জ্যোৎস্না একেবারে আকাশের সীমান্ত পর্যন্ত প্রসারিত হইয়া গেল, তখন মনে হইল যেন জনশূন্য চন্দ্রালোকের অসীম স্বপ্নরাজ্যের মধ্যে কেবল আমরা দুই জনে ভ্রমণ করিতেছি। একটি লাল শাল মনোরমার মাথার উপর হইতে নামিয়া তাহার মুখখানি বেষ্টন করিয়া তাহার শরীরটি আচ্ছন্ন করিয়া রহিয়াছে। নিস্তব্ধতা যখন নিবিড় হইয়া আসিল, কেবল একটি সীমাহীন দিশাহীন শুভ্রতা এবং শূন্যতা ছাড়া যখন আর কিছুই রইল না, তখন মনোরমা ধীরে ধীরে হাতটি বাহির করিয়া আমার হাত চাপিয়া ধরিল; অত্যন্ত কাছে সে যেন তাহার সমস্ত শরীরমন জীবনযৌবন আমার উপর বিন্যস্ত করিয়া নিতান্ত নির্ভর করিয়া দাঁড়াইল। পুলকিত উদ্‌বেলিত হৃদয়ে মনে করিলাম, ঘরের মধ্যে কি যথেষ্ট ভালোবাসা যায়। এইরূপ অনাবৃত অবারিত অনন্ত আকাশ নহিলে কি দুটি মানুষকে কোথাও ধরে। তখন মনে হইল, আমাদের ঘর নাই, দ্বার নাই, কোথাও ফিরিবার নাই, এমনি করিয়া হাতে হাতে ধরিয়া গম্যহীন পথে উদ্দেশ্যহীন ভ্রমণে চন্দ্রালোকিত শূন্যতার উপর দিয়া অবারিত ভাবে চলিয়া যাইব।     এইরূপে চলিতে চলিতে এক জায়গায় আসিয়া দেখিলাম, সেই বালুকারাশির মাঝখানে অদূরে একটি জলাশয়ের মতো হইয়াছে-- পদ্মা সরিয়া যাওয়ার পর সেইখানে জল বাধিয়া আছে।     সেই মরুবালুকাবেষ্টিত নিস্তরঙ্গ নিষুপ্ত নিশ্চল জলটুকুর উপরে একটি সুদীর্ঘ জ্যোৎস্নার রেখা মূর্ছিতভাবে পড়িয়া আছে। সেই জায়গাটাতে আসিয়া আমরা দুইজনে দাঁড়াইলাম-- মনোরমা কী ভাবিয়া আমার মুখের দিকে চাহিল, তাহার মাথার উপর হইতে শালটা হঠাৎ খসিয়া পড়িল। আমি তাহার সেই জ্যোৎস্নাবিকশিত মুখখানি তুলিয়া ধরিয়া চুম্বন করিলাম।     সেইসময় সেই জনমানবশূন্য নিঃসঙ্গ মরুভূমির মধ্যে গম্ভীরস্বরে কে তিনবার বলিয়া উঠিল, 'ও কে? ও কে? ও কে?'     আমি চমকিয়া উঠিলাম, আমার স্ত্রীও কাঁপিয়া উঠিলেন। কিন্তু পরক্ষণেই আমরা দুই জনেই বুঝিলাম, এই শব্দ মানুষিক নহে, অমানুষিকও নহে-- চরবিহারী জলচর পাখির ডাক। হঠাৎ এত রাত্রে তাহাদের নিরাপদ নিভৃত নিবাসের কাছে লোকসমাগম দেখিয়া উঠিয়াছে।     সেই ভয়ের চমক খাইয়া আমরা দুই জনেই তাড়াতাড়ি বোটে ফিরিলাম। রাত্রে বিছানায় আসিয়া শুইলাম; শ্রান্তশরীরে মনোরমা অবিলম্বে ঘুমাইয়া পড়িল। তখন অন্ধকারে কে একজন আমার মশারির কাছে দাঁড়াইয়া সুষুপ্ত মনোরমার দিকে একটিমাত্র দীর্ঘ শীর্ণ অস্থিসার অঙ্গুলি নির্দেশ করিয়া যেন আমার কানে কানে অত্যন্ত চুপিচুপি অস্ফুটকণ্ঠে কেবলই জিজ্ঞাসা করিতে লাগিল, 'ও কে? ও কে? ও কে গো?'     তাড়াতাড়ি উঠিয়া দেশালাই জ্বালাইয়া বাতি ধরাইলাম। সেই মুহূর্তেই ছায়ামূর্তি মিলাইয়া গিয়া, আমার মশারি কাঁপাইয়া, বোট দুলাইয়া, আমার সমস্ত ঘর্মাক্ত শরীরের রক্ত হিম করিয়া দিয়া হাহা-- হাহা-- হাহা-- করিয়া একটা হাসি অন্ধকার রাত্রির ভিতর দিয়া বহিয়া চলিয়া গেল। পদ্মা পার হইল, পদ্মার চর পার হইল,তাহার পরবর্তী সমস্ত সুপ্ত দেশ গ্রাম নগর পার হইয়া গেল-- যেন তাহা চিরকাল ধরিয়া দেশদেশান্তর লোকলোকান্তর পার হইয়া ক্রমশ ক্ষীণ ক্ষীণতর ক্ষীণতম হইয়া অসীম সুদূরে চলিয়া যাইতেছে; ক্রমে যেন তাহা জন্মমৃত্যুর দেশ ছাড়াইয়া গেল, ক্রমে তাহা যেন সূচির অগ্রভাগের ন্যায় ক্ষীণতম হইয়া আসিল, এত ক্ষীণ শব্দ কখনো শুনি নাই, কল্পনা করি নাই; আমার মাথার মধ্যে যেন আকাশ রহিয়াছে এবং সেই শব্দ যতই দূরে যাইতেছে কিছুতেই আমার মস্তিষ্কের সীমা ছাড়াইতে পারিতেছে না; অবশেষে যখন একান্ত অসহ্য হইয়া আসিল তখন ভাবিলাম, আলো নিবাইয়া না দিলে ঘুমাইতে পারিব না। যেমন আলো নিবাইয়া শুইলাম অমনি আমার মশারির পাশে, আমার কানের কাছে, অন্ধকারে আবার সেই অবরুদ্ধ স্বর বলিয়া উঠিল, 'ও কে, ও কে, ও কে গো।' আমার বুকের রক্তের ঠিক সমান তালে ক্রমাগতই ধ্বনিত হইতে লাগিল, 'ও কে, ও কে, ও কে গো। ও কে, ও কে, ও কে গো।' সেই গভীর রাত্রে নিস্তব্ধ বোটের মধ্যে আমার গোলাকার ঘড়িটাও সজীব হইয়া উঠিয়া তাহার ঘণ্টার কাঁটা মনোরমার দিকে প্রসারিত করিয়া শেলফের উপর হইতে তালে তালে বলিতে লাগিল, 'ও কে, ও কে, ও কে গো! ও কে, ও কে, ও কে গো!'     বলিতে বলিতে দক্ষিণবাবু পাংশুবর্ণ হইয়া আসিলেন, তাঁহার কণ্ঠস্বর রুদ্ধ হইয়া আসিল। আমি তাঁহাকে স্পর্শ করিয়া কহিলাম, 'একটু জল খান।' এমন সময় হঠাৎ আমার কেরোসিনের শিখাটা দপ দপ করিতে করিতে নিবিয়া গেল। হঠাৎ দেখিতে পাইলাম, বাহিরে আলো হইয়াছে। কাক ডাকিয়া উঠিল। দোয়েল শিস দিতে লাগিল। আমার বাড়ির সম্মুখবর্তী পথে একটা মহিষের গাড়ির ক্যাঁচ ক্যাঁচ শব্দ জাগিয়া উঠিল। তখন দক্ষিণবাবুর মুখের ভাব একেবারে বদল হইয়া গেল। ভয়ের কিছুমাত্র চিহ্ন রহিল না। রাত্রির কুহকে, কাল্পনিক শঙ্কার মত্ততায় আমার কাছে যে এত কথা বলিয়া ফেলিয়াছেন সেজন্য যেন অত্যন্ত লজ্জিত এবং আমার উপর আন্তরিক ক্রুদ্ধ হইয়া উঠিলেন। শিষ্টসম্ভাষণমাত্র না করিয়া অকস্মাৎ উঠিয়া দ্রুতবেগে চলিয়া গেলেন।     সেইদিনই অর্ধরাত্রে আবার আমার দ্বারে আসিয়া ঘা পড়িল, 'ডাক্তার! ডাক্তার!'",
      'Καλή δύναμη για όποιον και οποία αποφασίσει να το διαβάσει. Εγώ πάντως είχα τη δύναμη και το έγραψα. Πως οι Ευρωπαίοι πέφτουν πάντα  στην παγίδα των Αγγλοσαξόνων. Για να στηθεί μια φάκα για ποντίκια χρειάζεται ένα τυράκι.

      Για να στηθεί μια πολιτική φάκα χρειάζεται ένας χρήσιμος ηλίθιος.

      Θα ξεκινήσω από τη δεκαετία του 1950 για να κατανοήσουμε πως παίζεται το παιχνίδι. Μετά το Β’ ΠΠ υπήρξε τεράστια ανάγκη και ζήτηση για φτηνό πετρέλαιο και ενεργειακούς πόρους μιας και η ήπειρος βρισκόταν στο στάδιο της ανασυγκρότησης.

      Η Ευρώπη πρωτίστως στηριζόταν στο λιγνίτη, τον άνθρακα και το πετρέλαιο. Η παραγωγή και εμπορία των πρώτων, επαρκούσε αφού οι λιγνιτοφόρες και ανθρακοφόρες περιοχές του Βελγίου και της Γερμανίας, κάλυπταν τις απαιτούμενες ανάγκες. Το πετρέλαιο όμως στην Ευρώπη διατίθετο από τις χώρες της Μέσης Ανατολής. Πρωτίστως από το Ιράν και δευτερευόντως από το Ιράκ και τη Σαουδική Αραβία. Το 60% των αναγκών της γηραιάς ηπείρου για αυτό το προϊόν προερχόταν από το Ιράν του οποίου τη διαχείριση των πετρελαιοπηγών είχε αναλάβει αποκλειστικά η Αγγλική εταιρεία British Petroleum η γνωστή μας «ΒΡ». Τα κέρδη της εν λόγω εταιρείας σε διάστημα μόλις πέντε ετών 1947-1951

      είχαν φτάσει το 75% του κρατικού προϋπολογισμού του ίδιου του Ιράν. Χαρακτηριστικό είναι πως από το 1908 που ιδρύθηκε ως Anglo-Persian Oil Company

      μέχρι το 1946 δηλαδή για ένα διάστημα 38 ετών, το ενεργητικό της εταιρείας μόλις άγγιζε το 10% του ενεργητικού της τελευταίας πενταετίας 47-51. Και τότε συμβαίνει το εξής αναπάντεχο. Γίνονται εκλογές στο Ιράν, τις κερδίζει το κόμμα του Εθνικού Μετώπου και πρωθυπουργός γίνεται ο Μοχάμεντ Μοσαντέκ. Λίγους μήνες μετά το σχηματισμό κυβέρνησης, ο πρωθυπουργός Μοσαντέκ αποφασίζει να Εθνικοποιήσει τον πετρελαιοπαραγωγικό

      πλούτο της χώρας και να μεταφέρει τον έλεγχό του από την «ΒΡ» στη χώρα παραγωγής του, δηλαδή σε κρατική Ιρανική εταιρεία. Αυτό είχε τέσσερις άμεσες επιπτώσεις.

      Πρώτον έφευγε ο μεσάζων από τη μέση εν προκειμένω η Αγγλική Εταιρεία, δεύτερον χανόντουσαν υπέρογκα έσοδα για το Ηνωμένο Βασίλειο σε συνδυασμό με την απώλεια στρατηγικής και πολιτικής υπεροχής, τρίτον κατακλυζόταν η Ευρώπη από φτηνό πετρέλαιο γεμίζοντας παράλληλα τα κρατικά ταμεία του Ιράν και τέταρτον και βασικότερο θα συνέβαλε στην απεξάρτηση του Ιράν από την επιρροή των μεγάλων δυνάμεων, μέσω του δόγματος της «αρνητικής ισορροπίας» όπως την είχε φανταστεί ο Μοσαντέκ.

      Από μόνο του αυτό το γεγονός ενεργοποιεί τα αντανακλαστικά των Άγγλων οι οποίοι επιβάλουν οικονομικό εμπάργκο στο Ιράν στο οποίο συμμετέχουν, παρά την σύγκρουση των συμφερόντων τους και κράτη της Ευρώπης μεταξύ αυτών Γερμανία, Γαλλία, Ολλανδία, Ιταλία, Ισπανία και Πορτογαλία τα οποία και ζητούν την βοήθεια των ΗΠΑ. Ένα χρόνο μετά, από κοινού Ηνωμένο Βασίλειο και ΗΠΑ πραγματοποιούν

      πραξικόπημα στο Ιράν, φυλακίζουν τον Μοσαντέκ, δίνουν απεριόριστες εξουσίες στον Ρεζά Παχλεβι τον Σάχη της Περσίας και επαναφέρουν το προηγούμενο καθεστώς ελέγχου του Πετρελαίου.

      Χρήσιμος ηλίθιος ο Σάχης και τυράκι οι υπερεξουσίες και τα οικονομικά οφέλη σε βάρος της ίδιας του της πατρίδας. Παρότι η Ευρώπη συνολικά έβγαινε κερδισμένη από την κίνηση Μοσαντέκ, γιατί θα είχε φτηνό πετρέλαιο, εν τούτοις συντάχθηκε και στήριξε τις προσπάθειες των Αγγλοσαξόνων στο πραξικόπημα, για τα συμφέροντα μιας πολυεθνικής εν προκειμένω της «ΒΡ» και σε βάρος των λαών της.

      Ο Σάχης σχεδόν τριάντα χρόνια στην εξουσία δημιουργεί περιουσία τρεις φορές το ΑΕΠ της χώρας, καταπιέζει με βάναυσο τρόπο τον πληθυσμό και εφαρμόζει συστηματικό πογκρόμ διώξεων σε κάθε αντιφρονούντα. Ο λαός σε μια τόσο πλούσια χώρα ζει στην φτώχεια και στην εξαθλίωση μέχρι να επαναστατήσει το 1979 και να φέρει τον Αγιατολάχ, τους Μουλάδες και τον θρησκευτικό φονταμενταλισμό στην εξουσία. Η επανάσταση του 1979 οδηγεί τον Σάχη στην εξορία και τον θάνατό του.

      Με την εδραίωση των Μουλάδων στην εξουσία επανέρχεται το καθεστώς της εθνικοποίησης των πετρελαίων. Οι αγγλοσάξονες κάνουν ότι περνάει από το χέρι τους να ανατρέψουν αυτή την κατάσταση. Ξεκινούν το ίδιο παιχνίδι του εμπάργκο. Δεν τους βγαίνει

      και συνεχίζουν τη δοκιμασμένη συνταγή των πραξικοπημάτων. Δεν τους βγαίνει ούτε αυτό και πάνε παραπέρα. Εφαρμόζουν τη μέθοδο των πρακτόρων και της αντεπανάστασης.

      Και αφού εξαντλούν όλα τα περιθώρια αποφασίζουν να βρουν τον χρήσιμο ηλίθιο, με το σκεπτικό, από τη μια να εκδικηθούν το καθεστώς Χομεϊνί για το ρεζίλεμα που τους έκανε με την κατάληψη της Αμερικανικής πρεσβείας από Ιρανούς φοιτητές, και από την άλλη να ανακόψουν την αυξημένη παραγωγή και διάθεση πετρελαίου στην Ευρώπη η οποία αν και είχε επιβάλει εμπάργκο εν τούτοις μέσω των τριγωνικών συναλλαγών μια χαρά το προμηθευόταν.

      Πάμε τώρα στο δεύτερο ηλίθιο της ιστορίας. Εδώ θα τους αναλύσουμε όλους του ηλίθιους θα δούμε την τύχη που είχαν αλλά και το βρώμικο παιχνίδι των Αγγλοσαξόνων. Δεύτερος λοιπόν χρήσιμος ηλίθιος και μάλιστα διπλά, ο πρόεδρος του ΙΡΑΚ Σαντάμ Χουσείν. Η στρατηγική των Αγγλοσαξόνων ήταν απλή. Θα φούσκωναν τα μυαλά του υπερφίαλου Σαντάμ, περί υπερδύναμης της χώρας του στην περιοχή και ταυτόχρονα θα τον έπειθαν να επιτεθεί στο ΙΡΑΝ με το πρόσχημα ότι αυτό μεταφέρει στρατεύματα στα σύνορα (αυτό κάτι θυμίζει) για να επιτεθεί πρώτο, ενώ παράλληλα εξοπλίζει παραστρατιωτικές δυνάμεις Σηιτών μουσουλμάνων για την ανατροπή του ιδίου του Σαντάμ. Το τυράκι...ότι το ΙΡΑΝ είναι στρατιωτικά αποδυναμωμένο και ο Σαντάμ θα έχει την ευκαιρία να ανακτήσει από αυτό κάποια εδάφη που διεκδικούσε

      ιστορικά.

      Ο στόχος των ΗΠΑ ήταν να αποδυναμωθούν και τα δύο κράτη, και να αυξηθεί η τιμή του πετρελαίου που εκείνη την εποχή ήταν σε χαμηλά επίπεδα. Μάλιστα οι ΗΠΑ είχαν φροντίσει από πριν να πιέσουν τον ΟΠΕΚ (Οργανισμός Πετρελαιο-παραγωγικών Κρατών) να μην αυξήσει την παραγωγή για να μην πέσουν και άλλο οι τιμές. Ο Σαντάμ μπλέκεται σε έναν οκταετή πόλεμο και οι τιμές πετρελαίου εκτοξεύονται. Σε όλη τη διάρκεια του πολέμου οι Αμερικάνοι και Βρετανοί κερδίζουν τρισεκατομμύρια δολάρια, με τους πρώτους να φτάνουν στο σημείο να πουλούν

      για το κέρδος και από τα στρατηγικά αποθέματα

      που είχαν σε πετρέλαιο. Έφτασε το βαρέλι μεσοσταθμικά τα 30  δολάρια, τιμή ρεκόρ για την εποχή του. Ο πόλεμος τελειώνει χωρίς νικητή αλλά και τις δύο οικονομίες κατεστραμμένες. Και οι δύο όμως είναι χώρες παραγωγής πετρελαίου και γρήγορα θα ανακάμψουν ή τουλάχιστον έτσι πιστεύουν μια και η συγκυρία των 30 δολαρίων το βαρέλι τους ευνοεί για γρήγορα έσοδα και αύξηση του ΑΕΠ.

      Όμως υπολογίζουν χωρίς τον Αγγλοσάξονα.

      Η ολοκλήρωση της καταστροφής των ΙΡΑΝ-ΙΡΑΚ αλλά και η απληστία των Αγγλοσαξόνων για κέρδος έναντι όλων των άλλων δεν έχει ολοκληρωθεί.

      Τίθεται σε εφαρμογή το δεύτερο πλάνο του σχεδίου.

      Ενώ ο Σαντάμ υπολογίζει πως με τα 30 δολάρια που έχει το βαρέλι σε δύο χρόνια θα έχει ανακάμψει η οικονομία της χώρας, οι Αμερικάνοι βάζουν τώρα το Κουβέιτ στην τελευταία συνεδρίαση του ΟΠΕΚ να δηλώσει αύξηση της παραγωγής κατά 50%, παρά τις αντιρρήσεις των άλλων μελών κρατών.

      Αυτό έχει ως αποτέλεσμα να πέσει το βαρέλι σε μια νύχτα μέσα, από τα 30 δολάρια στα 18 και εν συνεχεία στα 12. Οι Αγγλοσάξονες έχουν χρησιμοποιήσει το Κουβέιτ ως Δούρειο Ίππο και αρχίζουν τώρα να δείχνουν στον Σαντάμ την προδοσία που αυτό έκανε. Μάλιστα

      για να ενισχύσουν την επιχειρηματολογία τους προς αυτόν, αναφέρουν πως οι μυστικές τους υπηρεσίες έχουν ανακαλύψει πως το Κουβέιτ κλέβει πετρέλαιο από δικό του πετρελαιοφόρο ορίζοντα και δικά του πηγάδια. Η Αμερικανίδα πρέσβης στο Ιράκ, Απρίλια Γκιλέσπι πείθει και σπρώχνει τον Σαντάμ ότι έχει τη σύμφωνη γνώμη των ΗΠΑ να εισβάλει

      στο Κουβέιτ.

      Ο Σαντάμ επιτίθεται

      και τα υπόλοιπα είναι γνωστά. Οι Αγγλοσάξονες, ΗΠΑ και Βρετανία με τη βοήθεια 32 συμμαχικών χωρών απελευθερώνουν το Κουβέιτ, εισβάλουν στο Ιράκ, εκτελούν τον Σαντάμ, καταστρέφουν τη χώρα και την οδηγούν σε κατακερματισμό. Για να δώσουν δε, άλλοθι στη δική τους επίθεση, διανθίζουν το σενάριο με δόσεις ανθρωπιστικής διάστασης με την δήθεν ύπαρξη και χρήση χημικών όπλων εκ μέρους του καθεστώτος του Ιράκ εναντίον των αντιφρονούντων.

      Ο χρήσιμος ηλίθιος δεν υπάρχει πια αλλά και οι χρήσιμοι ηλίθιοι Ευρωπαίοι δεν έχουν μοιραστεί, όσα τους είχαν υποσχεθεί οι Αγγλοσάξονες για να μπουν στον πόλεμο, ότι δήθεν

       θα κέρδιζαν μέσα από την ανασυγκρότηση της χώρας.

      Οι πλουτοπαραγωγικές δυνάμεις του Ιράκ έχουν λεηλατηθεί από τους Αγγλοσάξονες, ενώ οι πετρελαϊκές και κατασκευαστικές εταιρείες που δραστηριοποιούνται στο Ιράκ μετά τον πόλεμο είναι στο σύνολό τους Αμερικανοβρετανικές. Σε αντίθεση με την Ευρώπη που δέχεται τα κύματα των μεταναστών και της τρομοκρατίας εξ αιτίας ενός παιχνιδιού στο οποίο σύρθηκε και ενεπλάκη για τα συμφέροντα των ΗΠΑ και Βρετανίας.

      Για να φτάσουμε στο σωτήριο έτος 1990.

       Η ΕΣΣΔ από τις αρχές της δεκαετίας του 1980 αρχίζει να καταρρέει οικονομικά. Τρεις ήταν οι αιτίες που

      οδήγησαν στην κατάρρευση.

      Η πρώτη έχει να κάνει με το ίδιο το κομουνιστικό σύστημα και την αλλοίωση του στο πέρασμα του χρόνου. Το οικονομικό μοντέλο του κομουνισμού για την ΕΣΣΔ δεν ήταν λανθασμένο ή αποτυχημένο όπως θέλει να εμφανίζεται από τη Δύση. Οι ηγέτες και η νομενκλατούρα είχε διαφθαρεί σε μέγιστο βαθμό και είχε σαπίσει. Η δεύτερη αιτία ήταν ο πόλεμος στο Αφγανιστάν και η οικονομική αιμορραγία που υπέστη η χώρα χωρίς αιτία.

      Η πιο βασική όμως από τις προηγούμενες ήταν η ίδια η φιλοσοφία της συγκρότησης της ΕΣΣΔ. Μετά τον πόλεμο και τη συμφωνία της Γιάλτας η ΕΣΣΔ με κορμό τη Ρωσία βρέθηκε να αποτελείται από κράτη φτωχά και μη βιομηχανοποιημένα. Σε αντίθεση με την λεγόμενη Δύση συμπεριλαμβανομένης Αμερικής και Ιαπωνίας. Επί παραδείγματι στην ΕΣΣΔ συμπεριλαμβάνονται Πολωνία, Ουγγαρία, Τσεχοσλοβακία, Ρουμανία, Βουλγαρία, Λετονία, Εσθονία, Λιθουανία, Αρμενία, Γεωργία, τμήμα της Γερμανίας, οι Τουρανικές και Ευρασιατικές εθνοτικές κοινότητες που ουδεμία βιομηχανική ανάπτυξη είχαν πριν τον πόλεμο και ουδεμία ανάπτυξη μετέπειτα ακόμα και αγροτοκτηνοτροφική.

      Η Ρωσία κατά κύριο λόγο είχε επιφορτιστεί όχι μόνο να σηκώσει το βάρος της επιβίωσης αυτών των κρατών δορυφόρων αλλά ταυτόχρονα και να τις καθοδηγήσει μέσα από ένα κεντρικό και γραφειοκρατικό σύστημα λήψης αποφάσεων. Με άλλα λόγια ο βασικός κορμός Ρωσία έπρεπε όπως λέμε απλοϊκά, να ταΐσει την φτωχή περιφέρεια. Σε αντίθεση με τη Δύση που τα κράτη που την αποτελούσαν είχαν αξιοζήλευτη βαριά βιομηχανική παραγωγή πριν τον πόλεμο αλλά και ανεξαρτησία κινήσεων για την ανασυγκρότησή τους μετά από αυτόν. Οι Αμερικάνοι μπορεί να συμμετείχαν στον Β΄ΠΠ πόλεμο αλλά αυτός πέρα από ανθρώπινες ζωές δεν τους στοίχισε σε υλικοτεχνική υποδομή ή καταστροφή του παραγωγικού τους ιστού. Δεν διαδραματίστηκε στα εδάφη τους.

      Μια σημαντική διαφορά ανάμεσα στη Ρωσία και τις ΗΠΑ είναι…ενώ

      τη Ρωσία που ήταν ο κορμός του Ανατολικού μπλοκ, την απομυζούσαν τα κράτη δορυφόροι, οι ΗΠΑ κορμός του Δυτικού κόσμου απομυζούσαν αυτές τα κράτη δορυφόρους.

      Μάλιστα οι Αμερικάνοι προκειμένου να επισπεύσουν και επιταχύνουν την διάλυση της ΕΣΣΔ, ήδη από τη δεκαετία του 1980, δεν δίστασαν

      να προχωρήσουν και σε προβοκάτσια σε βάρος της, θυσιάζοντας αθώες ανθρώπινες ψυχές. Είναι γνωστό το τραγικό συμβάν της 1ης Σεπτεμβρίου του 1983 όταν οι αυτοί καθοδήγησαν το επιβατικό Νοτιοκορεάτικο τζάμπο 747 με 267 επιβάτες να πετά πάνω από την

      ΕΣΣΔ, γνωρίζοντας ότι αυτό έχει παραβιάσει χωρίς λόγο Εθνικό Εναέριο χώρο και θα καταρριφθεί όπως και έγινε. Ο στόχος τους ήταν όπως και αποδείχτηκε, να συμβεί το συγκεκριμένο γεγονός, για αυτό και έσπευσαν από την πρώτη στιγμή του τραγικού συμβάντος να ζητήσουν από την Ευρώπη και τον κόσμο να επιβληθούν κυρώσεις στην ΕΣΣΔ. Κυρώσεις που παρέμειναν ακόμα και όταν πολύ αργότερα από την έρευνα που διεξήχθη αποδείχτηκε πως η συγκεκριμένη πτήση εκτελούσε κατασκοπεία στον εναέριο χώρο της ΕΣΣΔ με ασπίδα αθώα θύματα και παρά τις εκκλήσεις της πολεμικής αεροπορίας της ΕΣΣΔ να αποχωρήσει, εκείνο συνέχισε να πετά εντός αυτού και να αγνοεί τις συστάσεις των πιλότων των ρωσικών μαχητικών. Για την ιστορία να πούμε πως ο μοναδικός ηγέτης από την τότε ΕΟΚ που αρνήθηκε να επιβάλει κυρώσεις, μέχρι να εξακριβωθούν τα ακριβή αίτια της κατάρριψης ήταν ο τότε πρωθυπουργός της Ελλάδας Ανδρέας Παπανδρέου.

      Αυτά και άλλα πολλά από τα πιο μικρά μέχρι τα μεγαλύτερα, σε συνδυασμό με τις κάθε λογής προβοκάτσιες των Αγγλοσαξόνων,

      έφεραν την οριστική κατάρρευση και διάλυση της ΕΣΣΔ το 1990. Οι πολιτικές, οικονομικές, και χωροταξικές αλλαγές που επήλθαν ανέδειξαν τις ΗΠΑ ως την απόλυτη παγκόσμια υπερδύναμη του πλανήτη, τόσο οικονομικά όσο και στρατιωτικά. Τουλάχιστον για μια εικοσαετία, οι ΗΠΑ διαμόρφωναν και καθοδηγούσαν τα αποτελέσματα του σε κάθε επίπεδο.

      Όμως, όπως πάντα συμβαίνει, μπορείς να έχεις πολλά για λίγο, δεν μπορεί να έχεις πολλά για πολύ. Όλες οι πατέντες και τα μονοπώλια έχουν ημερομηνία λήξης και ως τέτοια θεωρείται η ημερομηνία εμφάνισης του ανταγωνιστή. Στο τέλος της εικοσαετίας οι ΗΠΑ βρέθηκαν ξαφνικά με τρεις ανταγωνιστές που αμφισβητούσαν την παντοδυναμία των.

      Πρώτος η Κίνα που τις αμφισβητούσε οικονομικά και στρατιωτικά, δεύτερος η Ευρωπαϊκή Ένωση που σαν Νομισματική Ένωση τις αμφισβητούσε οικονομικά και τρίτος η Ρωσία που είχε επανακάμψει μετά την απελευθέρωσή της από τις υποχρεώσεις της ΕΣΣΔ και τις αμφισβητούσε οικονομικά και στρατιωτικά.

       Μέσα σε αυτή την εικοσαετία ο πληθυσμός της γης έχει αυξηθεί κατά περίπου ένα δισεκατομμύριο, χώρες αρχίζουν να αναπτύσσονται ραγδαία και οι ενεργειακές ανάγκες αυξάνονται.

       Η Κίνα από μόνη της απορροφά το 30% της παγκόσμιας ζήτησης πετρελαίου και δημιουργεί τεράστια στρατηγικά αποθέματα που από μόνα τους είναι ικανά να διαμορφώνουν την τιμή του. Χαρακτηριστικό είναι πως ο Πρόεδρος των ΗΠΑ Μπάιντεν τον Νοέμβριο του 2021 ζήτησε από την Κίνα να παρέμβει στη μείωση της τιμής του πετρελαίου.

      Η Αμερική με βάση όλα τα παραπάνω αρχίζει να συνειδητοποιεί πως χάνει το παιχνίδι της κυριαρχίας. Τα παγκόσμια αποθέματα πετρελαίου θα έχουν εξαντληθεί σε βάθος εξήντα ετών στην καλύτερη των

      περιπτώσεων και οι νέες μορφές ενέργειας θα είναι εναλλακτικές. Τα κέρδη θα μειωθούν ή θα εξαφανιστούν αλλά το χειρότερο για την Αμερική είναι ότι θα χάσει το στρατηγικό της πλεονέκτημα και ρόλο, από χώρες που θα έχουν την δυνατότητα να παράγουν και να προσφέρουν τέτοιες εναλλακτικές λύσεις. Συνεπώς πριν μπουν αυτές στο χορό θα πρέπει να μπει η ίδια η Αμερική και να κερδοσκοπήσει σύντομα. Όπως αναφέραμε και στην αρχή της ανάλυσης μας ο λιγνίτης, ο άνθρακας και το πετρέλαιο είναι οι αρχικοί ενεργειακοί πόροι. Τώρα προστίθενται το φυσικό ή υγροποιημένο αέριο, η αιολική και ηλιακή ενέργεια και η πυρηνική ενέργεια στην ασφαλέστερη μορφή της.

      Ο πρώτος σχεδιασμός των ΗΠΑ ήδη από τις αρχές του 1990 αφορά την κατάργηση του λιγνίτη. Προϊόν που παράγει ενέργεια είναι φτηνό, χρησιμοποιείται από τρίτες χώρες που όμως εξυπηρετούνται από αυτό και δεν είναι καταναλωτές των υπολοίπων μορφών ενέργειας. Με άλλα λόγια έχουμε χώρες που δεν είναι πελάτες των ΗΠΑ

      για τον απλούστατο λόγο δεν τις έχουν ανάγκη. Σε αυτούς τους μη πελάτες, ο στόχος των ΗΠΑ είναι να δημιουργηθούν ανάγκες ακόμα και αν δεν έχουν. Πως το κάνουν αυτό ? Με την κατάργηση του λιγνίτη. Πως όμως καταργούν τον λιγνίτη και με τι δικαιολογία ή πρόσχημα ? Κάλεσαν τα πλούσια κράτη μια μέρα στο Κιότο της Ιαπωνίας, έβαλαν και τον αντιπρόεδρό τους Αλ Γκόρ να προμοτάρει την καταστροφή του κλίματος και έβαλαν τα μικρά κράτη μέσω των διαφόρων Ενώσεων, ΕΕ ή Ένωση μικρών Νησιωτικών κρατών να υπογράψουν τη συμφωνία για την κατάργηση του λιγνίτη ενώ οι ίδιες οι ΗΠΑ συνεχίζουν μέχρι και σήμερα, να είναι στις πρώτες θέσεις σε παγκόσμια παραγωγή μαζί με τη Γερμανία και τη Βρετανία. Σαράντα οκτώ μικρές χώρες μεταξύ αυτών και η Ελλάδα υπέγραψαν στην ουσία την κατάργηση του λιγνίτη. Σαράντα οκτώ χώρες που όλες μαζί παράγουν λιγνίτη μόλις το 0,38% της παγκόσμιας παραγωγής συμπεριλαμβανομένης και της Ελλάδας σταμάτησαν τη χρήση λιγνίτη προς χάρη της προστασίας του κλίματος. Μάλιστα η Ελλάδα δεν χρησιμοποιεί καν λιγνίτη αλλά άνθρακα και μόνο για μια εταιρεία τη ΔΕΗ.

      Εφ΄ όσον με βάση τα παραπάνω η Ευρώπη πήρε μια τέτοια απόφαση λογικό είναι να αναζητήσει νέες μορφές ενεργειακών πόρων. Αυτές εντοπίζονται αρχικά στην Αιολική και Ηλιακή ενέργεια για να ακολουθήσει το αέριο φυσικό ή υγροποιημένο και όλες μαζί να αποτελέσουν τις Ανανεώσιμες Πηγές Ενέργειας τις λεγόμενες ΑΠΕ. Όμως οι δύο πρώτες δεν καλύπτουν τις ενεργοβόρες ανάγκες της Βιομηχανικής Ευρώπης ή μάλλον τις καλύπτουν σε ποσοστό μόλις 30% και αυτό υπό ιδανικές καιρικές συνθήκες. Εκείνο που απομένει είναι το αέριο. Εκείνη που μπορεί να το προμηθεύσει είναι η Ρωσία και μάλιστα σε τεράστιες ποσότητες. Η σχέση Ευρώπης Ρωσίας με συνδετικό κρίκο το αέριο θα καλύψει τις ανάγκες της Ευρώπης, θα αυξήσει την παραγωγική της βάση, θα κάνει την οικονομία της πιο ανταγωνιστική, θα δημιουργήσει εξωστρέφεια κεφαλαίων ανάμεσα στις δυο αυτές οικονομίες Ευρώπης Ρωσίας, θα αποδυναμώσει τις συναλλαγές με τις ΗΠΑ, τη Βρετανία και τα πετρελαιοπαραγωγά κράτη δορυφόρους των,

      Ιράκ, Ηνωμένα Αραβικά Εμιράτα, Κουβέιτ, Κατάρ, Σαουδική Αραβία. Υπ όψη πως σε όλα αυτά τα κράτη κουμάντο κάνουν Αμερικανοβρετανικές εταιρείες κολοσσοί. Όπου δεν έκαναν βλέπε Λιβύη κατέστρεψαν την αγορά.

      Από την άλλη θα γιγαντώσει την οικονομία της Ρωσίας αλλά το κυριότερο θα της προσδώσει στρατηγικό χαρακτήρα και πλεονέκτημα. Μια αμφίδρομη ισότιμη σχέση οικονομικά ισχυρής Ευρώπης και στρατιωτικά πανίσχυρης Ρωσίας

      θα αλλάξει το status quo

      του πλανήτη ολόκληρου, επί το λαϊκότερο θα τινάξει την μπάνκα στον αέρα.

      Όλα τα παραπάνω τα γνώριζαν οι Αγγλοσάξονες και για αυτό ήδη από τις αρχές του 2000 άρχισαν να πιέζουν πρώτα τη Ρωσία και μετά την ίδια την Ευρώπη, προκειμένου να σπάσουν αυτή τη διασύνδεση. Όπως όμως προ είπαμε

      για την επίτευξη του στόχου των Αγγλοσαξόνων χρειάζεται ο χρήσιμος ηλίθιος και το τυράκι. Οι αγγλοσάξονες ψάχνουν πάντα για το μαλακό υπογάστριο κάθε χώρας, ψάχνουν πάντα να δημιουργούν τη λεγόμενη θεωρία «Διαίρει και βασίλευε» Το μαλακό υπογάστριο της Ρωσίας μετά τη διάλυση της ΕΣΣΔ ήταν πως οι ΗΠΑ αναγνώρισαν τις αποσχιθείσες περιοχές από την Ρωσία και αυτή το δέχτηκε, με τα σύνορα που ίσχυαν πριν της συμφωνίας Μολότοφ-Ρίμπεντροπ το 1939. Αυτό είχε σαν αποτέλεσμα στα αποσχιθέντα κράτη να υπάρχουν ολόκληρες εδαφικές περιοχές με καθαρά Ρωσικό πληθυσμό που ζητούσε την αυτονομία του. Εδώ ας λάβουμε υπ όψη μας πως το πολιτικό Διοικητικό Σύστημα της ΕΣΣΔ αλλά και της Ρωσίας ήταν και είναι δομημένο στην ύπαρξη τέτοιων Αυτόνομων Διοικητικά Δημοκρατιών εντός των συνόρων της. Ήταν άλλωστε Συνταγματικά κατοχυρωμένο. Ακόμα και σήμερα εντός των συνόρων της Ρωσίας υπάρχουν 22 Αυτόνομες Δημοκρατίες, (μία από αυτές την Ουντμουρτία στην πόλη Γκλάζοφ την έζησα για 25 ολόκληρα χρόνια)

      βέβαια όχι με όλα τα δικαιώματα που είχαν επί ΕΣΣΔ αλλά υπάρχουν. Το μαλακό υπογάστριο ήταν η ίδια η Γεωργία. Η Γεωργία και η Αρμενία ήταν οι πρώτες χώρες που αποπειράθηκαν οι ΗΠΑ να εντάξουν στο ΝΑΤΟ. Αυτό θα τους έδινε με τη Γεωργία στρατηγικό πλεονέκτημα και πρόσβαση στον Εύξεινο Πόντο απέναντι από τα στρατηγικά λιμάνια της Οδησσού και της Κριμαίας και από την άλλη με την Αρμενία θα έβγαιναν στην πλάτη του Ιράν. Το σχέδιο απέτυχε επειδή εκείνη την εποχή Πρόεδρος της Γεωργίας συν έπεσε να είναι ο Εντβαρντ

      Σεβαρντνάτζε πρώην υπουργός Εξωτερικών της ΕΣΣΔ με τρομακτική εμπειρία στα παιχνίδια των ΗΠΑ. Όμως ο χρήσιμος ηλίθιος και το τυράκι βρέθηκαν. Το 2008 οι ΗΠΑ έβαλαν το ανδρείκελο πρόεδρο της Γεωργίας

      Μιχαήλ Σαακασβίλι να επιτεθεί στη Ρωσική περιοχή της Νότιας Οσετίας με το πρόσχημα της κατάληψης. Οι Αγγλοσάξονες του φούσκωσαν τα μυαλά όπως και στον Σαντάμ ότι τώρα έχει τη στήριξή τους και τη δύναμη να κερδίσει. Ο Σαακασβίλι επιτέθηκε και έσπασε τα μούτρα του. Οι Αγγλοσάξονες ποσώς ενδιαφέρονταν για την τύχη της επέμβασης, για τους νεκρούς, για τον ίδιο τον Πρόεδρο της Γεωργίας. Εκείνο που τους ενδιέφερε ήταν να αναγκάσουν την Ρωσία να επέμβει, να την κατηγορήσουν για εισβολή σε μια τρίτη χώρα και να της επιβάλουν κυρώσεις. Έβλεπαν πως η Ρωσία αρχίζει να αναπτύσσεται και έπρεπε με τις κυρώσεις να την φρενάρουν. Σήμερα για την ιστορία ο Σαακασβίλι είναι φυλακισμένος στη Γεωργία για εσχάτη προδοσία. Όσα όμως ακολουθούν την πορεία Σαακασβίλι μετά τον διωγμό του από τη Γεωργία είναι τραγελαφικά και αξίζει να τα δούμε για να καταλάβουμε τα παιχνίδια των Αγγλοσαξόνων.

      Ο Σαακασβίλι χρήσιμος ηλίθιος παίζει το παιχνίδι τους, στη συνέχεια τον φυγαδεύουν και τον στέλνουν να βρει άσυλο και να προστατευθεί στην Ουκρανία. Στην Ουκρανία οι ΗΠΑ πιέζουν τον τότε Πρόεδρο της Πέτρο Ποροσένκο να του δώσει Ουκρανική Υπηκοότητα, και στη συνέχεια βάζουν τον σημερινό Πρόεδρο της Ουκρανίας Ζελένσκι να φυλακίσει τον πρώην Πρόεδρο Ποροσένκο, να άρει την υπηκοότητα του Σαακασβίλι και να τον επιστρέψει στη Γεωργία για να δικαστεί, προκειμένου να εξομαλυνθούν οι σχέσεις Γεωργίας και ΗΠΑ μετά την ατυχή εισβολή της πρώτης. Να επισημάνουμε πως από το 1990 με την διάλυση της ΕΣΣΔ η Ρωσία όχι μόνο δεν επιτέθηκε σε κανένα κράτος, όχι μόνο παρείχε απόλυτη στήριξη και βοήθεια στις αποσχιθείσες περιοχές αλλά προχώρησε και ένα βήμα παραπέρα. Ίδρυσε την Ανεξάρτητη Κοινοπολιτεία Κρατών (ΚΑΚ) για να τις προστατεύσει μέχρι να στηθούν στα πόδια τους. Καθόλου τυχαίο ότι ιδρυτικό κράτος μαζί με την Ρωσία ήταν η Ουκρανία.

      Στον αντίποδα οι ΗΠΑ εκμεταλλεύτηκαν την διάλυση της ΕΣΣΔ και της Ρωσίας και έσπευσαν πρώην Δημοκρατίες του λεγόμενου ανατολικού μπλοκ συνολικά 14 τον αριθμό, να τις εντάξουν στο ΝΑΤΟ, παραβιάζοντας τη Συμφωνία που είχαν κάνει με τους Ρώσους, προκειμένου να ενοποιηθούν οι δύο Γερμανίες. Συμφωνία που προέβλεπε μη επέκταση του ΝΑΤΟ σε αυτές τις Δημοκρατίες. Αλλά οι ΗΠΑ εκμεταλλεύτηκαν και το τέλος του ψυχρού πολέμου και την ανυπαρξία του αντίπαλου δέους για να επέμβουν σε άλλες κυρίαρχες χώρες. Συνολικά από το 1990 μέχρι σήμερα οι ΗΠΑ έχουν επέμβει στρατιωτικά σε 49 κυρίαρχα κράτη. Παρόλα αυτά ο Πούτιν και η Ρωσία τους ανέχτηκαν. Όμως κάποτε ο κόμπος φτάνει στο χτένι. Και φτάνει όταν αποκαλύπτεται ότι οι ΗΠΑ θέλουν να στραγγαλίσουν τη Ρωσία οικονομικά και να την κάνουν δορυφόρο τους.

      Για να θυμηθούμε κάποια γεγονότα. Πόλεμος Σερβίας. Πόλεμος στον αγωγό

      Μπουργκάς- Αλεξανδρούπολης. Εδώ να μείνουμε. Η Ρωσία με σταθερούς δύο παίκτες κράτη, τη Βουλγαρία και την Ελλάδα διαβλέπει στην κατασκευή ενός αγωγού διακίνησης αργού πετρελαίου που θα έχει γεωπολιτική σταθερότητα και θα προμηθεύει την Ευρώπη με Ρωσικό πετρέλαιο. Όλες οι κυβερνήσεις από τον Κωνσταντίνο Μητσοτάκη, Ανδρέα Παπανδρέου, Κώστα Σημίτη

      μέχρι τον Κώστα Καραμανλή, συμπεριλαμβανομένης και της ΕΕ κατανοούν την δύναμη αυτού του αγωγού και δίνουν το πράσινο φως. Έλληνες και Βούλγαροι συμφωνούν στο αρχικό σχέδιο

      των πόρων και ο αγωγός ξεκινά με στόχο το 2010 να έχει ολοκληρωθεί. Ξαφνικά και ως δια μαγείας οι Βούλγαροι με πρόσχημα το περιβάλλον κάνουν πίσω και ο αγωγός ακυρώνεται. Ο τότε Πρόεδρος της Βουλγαρίας Γκεόργκι Παρβάνοφ άφησε να εννοηθεί ότι υπήρχε ειλημμένη συμφωνία ακύρωσης του αγωγού από παλαιότερα προκειμένου να ενταχθεί η Βουλγαρία στο ΝΑΤΟ. Ένα άλλο παράδειγμα στραγγαλισμού της Ρωσίας και μάλιστα πρόσφατο είναι τα γεγονότα στο Καζακστάν. Η Δύση τα παρουσίασε σαν αντίδραση των Καζάκων προς την κυβέρνηση για την ακρίβεια των τιμών. Η πραγματικότητα όμως είναι άλλη και έχει την πηγή της στο πραξικόπημα κατά του Ερντογάν. Όταν ο Ερντογάν κατήγγειλε τις ΗΠΑ για συμμετοχή της στο πραξικόπημα δεν είχε άδικο. Η φιλία μεταξύ Ερντογάν και Πούτιν αφορμή είχε την προειδοποίηση του Πούτιν προς αυτόν ότι επίκειται πραξικόπημα εναντίον του. Οι μυστικές υπηρεσίες της Ρωσίας είχαν εντοπίσει μεγάλο όγκο ατόμων Αμερικανικής Υπηκοότητας

      που είχαν εισέλθει στην Τουρκία με διπλωματικά διαβατήρια. Χαρακτηριστικό είναι πως περίπου 3.000 άτομα πηγαινοερχόντουσαν στην Τουρκία με Αμερικάνικα Διπλωματικά διαβατήρια και ενημέρωσαν τις αντίστοιχες υπηρεσίες της Τουρκίας. Οι Τούρκοι έκαναν έλεγχο και επαλήθευσαν τις πληροφορίες της Μόσχας. Κάτι ανάλογο έγινε και στο Καζακστάν. Ο στόχος των ΗΠΑ μέσω πρακτόρων της, ήταν η ανατροπή του προέδρου Τοκάγιεφ και η τοποθέτηση νέου Προέδρου τύπου Ζελένσκι. Οι ΗΠΑ ήθελαν την αποχώρηση του Καζακστάν από την Κοινοπολιτεία με τη Ρωσία και τον έλεγχο του διαστημικού σταθμού του Μπαικονούρ. Ταυτόχρονα τον αποκλεισμό της Ρωσίας από την πρόσβαση σε ουράνιο και τον έλεγχο αυτού,

      αφού το Καζακστάν είναι ο βασικός τροφοδότης της Ρωσίας σε ουράνιο και η πρώτη χώρα παραγωγής του παγκόσμια. Και εδώ όμως οι Αμερικάνοι έσπασαν τα μούτρα τους.  Και ερχόμαστε στο ζήτημα της Ουκρανίας.   Στο διάγγελμά του ο Πούτιν έκανε τεκμηριωμένα μια πλήρη ιστορική περιγραφή για τη χώρα Ουκρανία. Οι αγγλοσάξονες από την αρχή του 2010 είχαν εντοπίσει την χρησιμότητα της Ουκρανίας τόσο για την Ευρώπη, όσο και για τη Ρωσία. Θεωρούσαν ότι ελέγχοντας την Ουκρανία και τους αγωγούς φυσικού αερίου αυτής θα ελέγχουν τα πάντα. Οι συνθήκες όμως δεν ευνοούσαν αφού οι σχέσεις των δύο προέδρων Γιανουκόβιτς και Πούτιν ήταν άριστες. Έτσι απλά περίμεναν και η χρυσή ευκαιρία ήρθε όταν ο τότε πρόεδρος της Ουκρανίας Γιονουκόβιτς,  αποχώρησε από τις συνομιλίες για ένταξη της χώρας του στην ΕΕ.

      Η πεπονόφλουδα είχε στηθεί. Απαιτούσαν από τον Γιανουκόβιτς πως για να μπει στην ΕΕ η χώρα , έπρεπε να μπει και στο ΝΑΤΟ. Εκβιασμός που δεν μπορούσε να περάσει λόγω της αντίδρασης της Μόσχας. Ο Γιανουκόβιτς διέκοψε τις συνομιλίες και με το καλά οργανωμένο σχέδιο που είχαν στήσει οι μυστικές υπηρεσίες της Βρετανίας και των ΗΠΑ ξεκίνησαν οι διαδηλώσεις και η αναταραχή στο Κίεβο.

      Ο Γιανουκόβιτς έπεσε και τη θέση του πήρε ο Πέτρο Ποροσένκο. Σε όλη τη διάρκεια της θητείας του ήταν και αυτός σθεναρά αντίθετος στην είσοδο της Ουκρανίας στο ΝΑΤΟ αν και είχε στηρίξει ηθικά και οικονομικά την εξέγερση των Ουκρανών στο Μαιντάν το 2014. Έτσι οι ΗΠΑ εμφανίζουν το 2019 τον Ζελένσκι. Ποιος είναι ο Ζελένσκι αναζητήστε τον στο Google. Η κερκόπορτα είχε ανοίξει. Το πρώτο πράγμα που ζήτησε ο Ζελένσκι, ήταν να μπει η χώρα του στο ΝΑΤΟ. Αυτό θα εξυπηρετούσε τα σχέδια των Αγγλοσαξόνων. Ο Πούτιν δεν θα το δεχόταν ποτέ αυτό και έτσι θα τον έσερναν σε επέμβαση κατά της Ουκρανίας. Για τον Πούτιν ήταν μπρος γκρεμός και πίσω ρέμα. Αν δεχόταν την είσοδο της Ουκρανίας στο ΝΑΤΟ, πρώτον θα έπεφτε και δεύτερον η Ρωσία θα στραγγαλιζόταν γεωπολιτικά και στρατηγικά. Όλα αυτά όμως βασικό στόχο είχαν μια σύγκρουση Ευρώπης Ρωσίας. Το κατόρθωσαν οι Αγγλοσάξονες ? Θα πω ΝΑΙ μετά βεβαιότητας.

      Πρώτον όπως και σε όλες τις περιπτώσεις ζήτησαν κυρώσεις. Στην ουσία μια και βασική ζητούσαν. Να διακοπεί ο αγωγός φυσικού αερίου προς την Ευρώπη. Η Ευρώπη έπεσε στην παγίδα. Δεύτερον με τις κυρώσεις ανακόπτουν την οικονομική άνοδο της Ευρώπης. Τρίτον σπάνε τους δεσμούς ανάμεσα σε αυτή και τη Ρωσία. Τέταρτον στραγγαλίζουν την οικονομία της Ρωσίας. Πέμπτο αναγκάζουν την Ευρώπη να μεταφέρει τουλάχιστον ένα τρις δολάρια προς τις δικές τους εταιρείες φυσικού αερίου που εδρεύουν σε ΗΠΑ και Κατάρ. Εδώ σημειώστε και δεν είναι καθόλου τυχαίο γιατί οι ΗΠΑ αντέδρασαν

      στην δημιουργία του East med.

      Τι είπαν οι Αμερικάνοι ξεδιάντροπα φανερώνοντας τις προθέσεις τους. Θα καλύψουμε εμείς τις ανάγκες της Ευρώπης με υγροποιημένο αέριο. Δεν είπαν όμως την τιμή.

      Ας δούμε όμως και πως οι Αγγλοσάξονες έσπρωξαν τον Πούτιν σε επέμβαση. Τι ζητούσε ο Πούτιν στις διαπραγματεύσεις. Πρώτον να μη γίνει μέλος του ΝΑΤΟ η Ουκρανία και δεύτερον να σεβαστεί η Ουκρανία τη συμφωνία του Μίνσκ για την αυτονομία του Ντονμπάς. Δυο πολύ απλά πράγματα που δεν ήταν σε βάρος κανενός. Γιατί όμως ο Πρόεδρος της Ουκρανίας στάθηκε τόσο ανένδοτος ? Απλά γιατί έπαιζε το ρόλο του χρήσιμου ηλίθιου.

      Για να σκεφτούμε τι θα είχε συμβεί αν ο Ζελένσκι είχε δεχτεί τις διαπραγματεύσεις.

      Η Ρωσία δεν θα είχε επέμβει, οι Ευρωπαίοι δεν θα επέβαλαν κυρώσεις, ο αγωγός θα γινόταν και οι Αγγλοσάξονες θα έμεναν με τον Γιακουμή στο χέρι. Θα ισχυριστεί κάποιος ότι αυτά θα γινόντουσαν και αν η Ρωσία δεν έμπαινε στην Ουκρανία. Τότε όμως

      θα έμπαινε το ΝΑΤΟ και τα ίδια θα δημιουργούσαν οι Αγγλοσάξονες αργότερα με τη Ρωσία να έχει πλέον να αντιμετωπίσει το ΝΑΤΟ και όχι την Ουκρανία.

      Τσακίζεις το Χίτλερ πριν

      αναπτυχθεί. Αν οι Ευρωπαίοι τον είχαν τσακίσει από το 1938 δεν θα είχαμε Β’ ΠΠ.

      Υ.Γ. Οι Αγγλοσάξονες και κυρίως οι ΗΠΑ θα κερδίσουν και από το σιτάρι, θα πλήξουν και την Κίνα που έχει συμβόλαια με την Ουκρανία και απορροφά το 45% της συνολικής παραγωγής της.'
    ]
  end

  let(:count) { 10 }

  describe 'Stopwords' do
    describe 'parallel filtered' do
      specify do
        3.times do
          benchmark = Benchmark.measure do
            count.times do
              contents.each do |text|
                Texter::Content.new(text: text).filtered
              end
            end
          end
          puts benchmark
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
