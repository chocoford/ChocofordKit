//
//  SupportChocofordView.swift
//  ChocofordKit
//
//  Created by Dove Zachary on 2024/10/1.
//

import SwiftUI
import StoreKit

public struct SupportChocofordView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) var dismiss
    @Environment(\.alertToast) var alertToast
    
    var isAppStore: Bool
//    var privacyPolicy: URL?
//    var termsOfUse: URL?
    
    public init(isAppStore: Bool) {
        self.isAppStore = isAppStore
    }
    
    @State private var isSupportHistoryPresented = false
    @State private var purchaseHistory: [StoreKit.Transaction] = []

    public var body: some View {
        ViewSizeReader { size in
            ZStack {
                // Main content
                VStack(spacing: 20){
                    Text("Your support is the biggest motivation for me")
                        .font(.title)
                        .padding(.bottom, 20)
                    if isAppStore {
                        purchaseItemsAppStore()
                    } else {
                        purchaseItems()
                    }
                    HStack {
                        if isAppStore {
                            Button {
                                isSupportHistoryPresented.toggle()
                            } label: {
                                Text("Support history")
                            }
                            
                            AsyncButton {
                                try await AppStore.sync()
                            } label: {
                                Text("Restore purchase")
                            }
                            .buttonStyle(.borderless)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                        }
                    }
                }
                .padding(40)
                .offset(y: isSupportHistoryPresented ? -size.height : 0)
                .animation(.smooth, value: isSupportHistoryPresented)
                
                if isAppStore {
                    // Purchase history
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(purchaseHistory, id: \.self) { transaction in
                                PurchaseHistoryItemView(
                                    allProducts: Set(suppoprts + memberships),
                                    transaction: transaction
                                )
                            }
                        }
                        .padding(40)
                    }
                    .overlay(alignment: .topLeading) {
                        Button {
                            isSupportHistoryPresented.toggle()
                        } label: {
                            Label("Back", systemSymbol: .chevronUp)
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.text(square: true))
                        .padding()
                    }
                    .offset(y: isSupportHistoryPresented ? 0 : size.height)
                    .animation(.smooth, value: isSupportHistoryPresented)
                    .task {
                        do {
                            var iterator = StoreKit.Transaction.all.makeAsyncIterator()
                            while let result = await iterator.next() {
                                switch result {
                                    case .unverified(let signedType, let verificationError):
                                        break
                                    case .verified(let signedType):
                                        self.purchaseHistory.append(signedType)
                                }
                            }
                        } catch {
                            alertToast(error)
                        }
                    }
                }
            }
        }
    }
    
    @State private var activeTransactions: Set<StoreKit.Transaction> = []
    @State private var transactionUpdates: Task<Void, Never>?

    @State private var suppoprts: [Product] = []
    @State private var memberships: [Product] = []
    
    let productIdentifiers = [
        // consumable
        "Donation_Lv1",
        "Donation_Lv2",
        "Donation_Lv3",
        "Donation_Lv4",
        "Donation_Lv5",
        "Donation_Lv6",
        
        // subscriptions
        "Membership_Lv1_Monthly",
        "Membership_Lv2_Monthly",
    ]
    
    @MainActor @ViewBuilder
    private func purchaseItemsAppStore() -> some View {
        let roundedRectangle = RoundedRectangle(cornerRadius: 8)
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Support")
                ZStack {
                    if #available(iOS 16.0, macOS 13.0, *) {
                        FlexStack(horizontalSpacing: 12) {
                            ForEach(suppoprts) { product in
                                AsyncButton {
                                    try await self.purchaseProduct(product)
                                } label: {
                                    Text(product.displayPrice)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        HStack {
                            ForEach(suppoprts[0..<3]) { product in
                                AsyncButton {
                                    try await self.purchaseProduct(product)
                                } label: {
                                    Text(product.displayPrice)
                                }
                            }
                        }
                        HStack {
                            ForEach(suppoprts[3...]) { product in
                                AsyncButton {
                                    try await self.purchaseProduct(product)
                                } label: {
                                    Text(product.displayPrice)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.fill)
                .padding(12)
                .background {
                    ZStack {
                        roundedRectangle.fill(.regularMaterial)
                        if #available(macOS 14.0, iOS 17.0, *) {
                            roundedRectangle.stroke(.separator)
                        } else {
                            roundedRectangle.stroke(.secondary)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading) {
                Text("Membership")
                ZStack {
                    if #available(iOS 16.0, macOS 13.0, *) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 10) {
                                membershipsView()
                            }
                            VStack(spacing: 10) {
                                membershipsView()
                            }
                        }
                    } else {
                        if horizontalSizeClass == .compact {
                            VStack(spacing: 10) {
                                membershipsView()
                            }
                        } else {
                            HStack(spacing: 10) {
                                membershipsView()
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(12)
                .frame(maxWidth: .infinity)
                .background {
                    ZStack {
                        roundedRectangle.fill(.regularMaterial)
                        if #available(macOS 14.0, iOS 17.0, *) {
                            roundedRectangle.stroke(.separator)
                        } else {
                            roundedRectangle.stroke(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                do {
                    let appProducts = try await Product.products(for: productIdentifiers)
                    
                    for product in appProducts {
                        switch product.type {
                            case .consumable:
                                self.suppoprts.append(product)
                            case .autoRenewable:
                                self.memberships.append(product)
                            default:
                                break
                        }
                    }
                    
                    self.suppoprts.sort(by: {$0.price < $1.price})
                    self.memberships.sort(by: {$0.price < $1.price})
                    await self.fetchActiveTransactions()
                } catch {
                    print(error)
                    alertToast(error)
                }
            }
            
            transactionUpdates = detach {
                for await update in StoreKit.Transaction.updates {
                    if let transaction = try? update.payloadValue {
                        await fetchActiveTransactions()
                        await transaction.finish()
                    }
                }
            }
        }
    }
    
    @MainActor @ViewBuilder
    private func membershipsView() -> some View {
        ForEach(self.memberships) { membership in
            let hasPurchased = activeTransactions.first(where: {$0.productID == membership.id})?.isUpgraded == false
            AsyncButton {
                if hasPurchased {
                    
                } else {
                    try await self.purchaseProduct(membership)
                }
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(membership.displayName)
                        Group {
                            Text(membership.displayPrice)
                            +
                            Text(" / ")
                            +
                            Text(membership.subscription?.subscriptionPeriod.unit == .month ? "month" : "year")
                        }
                            .font(.callout)
                    }
                    Spacer()
                    if hasPurchased {
                        Image(systemSymbol: .checkmarkCircle)
                            .foregroundStyle(.green)
                    }
                }
            }
            .buttonStyle(
                .fill(
                    style: hasPurchased ? AnyShapeStyle(Color(hexString: "#177E19")) : AnyShapeStyle(Color.accentColor)
                )
            )
        }
    }
    
    private func purchaseProduct(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
            case .success(let verificationResult):
                if let transaction = try? verificationResult.payloadValue {
                    activeTransactions.insert(transaction)
                    await transaction.finish()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
        }
    }
    
    private func fetchActiveTransactions() async {
        var activeTransactions: Set<StoreKit.Transaction> = []
        
        for await entitlement in StoreKit.Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                activeTransactions.insert(transaction)
            }
        }
        await MainActor.run {
            self.activeTransactions = activeTransactions
        }
    }

    @MainActor @ViewBuilder
    private func purchaseItems() -> some View {
        HStack {
            Link(destination: URL(string: "https://www.chocoford.com/donation")!) {
#if canImport(AppKit)
                if let nsImage = NSImage(contentsOfFile: Bundle.module.path(forResource: "Donation Button", ofType: "png")!) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                }
#elseif canImport(UIKit)
                if let uiImage = UIImage(contentsOfFile: Bundle.module.path(forResource: "Donation Button", ofType: "png")!) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
#endif
            }
            .buttonStyle(.plain)
            .frame(width: nil, height: 40)
        }
    }
}

struct PurchaseHistoryItemView: View {
//    var allProducts: Set<Product>
    var transaction: StoreKit.Transaction
    var product: Product?
    
    init(allProducts: Set<Product>, transaction: StoreKit.Transaction) {
//        self.allProducts = allProducts
        self.transaction = transaction
        self.product = allProducts.first(where: {$0.id == transaction.productID})
    }
    
    var body: some View {
        if let product {
            ZStack {
                switch product.type {
                    case .consumable:
                        VStack(alignment: .leading) {
                            Text("Supported \(product.displayPrice)")
                            Text(transaction.purchaseDate.formatted())
                                .foregroundStyle(.secondary)
                        }
                    case .autoRenewable:
                        VStack(alignment: .leading) {
                            Text("Joined membership \(product.displayPrice)")
                            Text(transaction.purchaseDate.formatted())
                                .foregroundStyle(.secondary)
                        }
                        
                    default:
                        EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}

#Preview {
    if #available(macOS 13.0, *) {
        SupportChocofordView(isAppStore: true)
            .padding()
    }
}
